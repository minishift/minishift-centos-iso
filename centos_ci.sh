#!/bin/bash

# Output command before executing
set -x

# Exit on error
set -e

# GitHub user
REPO_OWNER="minishift"
REPO_NAME="minishift-centos-iso"

########################################################
# Exit with message on failure of last executed command
# Arguments:
#   $1 - Exit code of last executed command
#   $2 - Error message
########################################################
function exit_on_failure() {
  if [[ "$1" != 0 ]]; then
    echo "$2"
    exit 1
  fi
}

# Source environment variables of the jenkins slave
# that might interest this worker.
function load_jenkins_vars() {
  if [ -e "jenkins-env" ]; then
    cat jenkins-env \
      | grep -E "(JENKINS_URL|GIT_BRANCH|GIT_COMMIT|BUILD_NUMBER|ghprbSourceBranch|ghprbActualCommit|BUILD_URL|ghprbPullId|CICO_API_KEY|GITHUB_TOKEN|JOB_NAME|RELEASE_VERSION)=" \
      | sed 's/^/export /g' \
      > ~/.jenkins-env
    source ~/.jenkins-env
  fi

  echo 'CICO: Jenkins ENVs loaded'
}

function install_required_packages() {
  # Install EPEL repo
  yum -y install epel-release
  # Get all the deps in
  yum -y install make \
                 git \
                 livecd-tools \
                 curl \
                 docker \
                 parted \
                 kvm \
                 qemu-kvm \
                 libvirt \
                 python-requests \
                 git \
                 jq

  echo 'CICO: Required packages installed'
}

function start_libvirt() {
  systemctl start libvirtd
}

function setup_kvm_machine_driver() {
  curl -L https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.10.0/docker-machine-driver-kvm-centos7 > /usr/local/bin/docker-machine-driver-kvm && \
  chmod +x /usr/local/bin/docker-machine-driver-kvm
}

function perform_artifacts_upload() {
  rm -rf build/bin # Don't upload bin folder
  set +x

  # For PR build, GIT_BRANCH is set to branch name other than origin/master
  if [[ "$GIT_BRANCH" = "origin/master" ]]; then
    # http://stackoverflow.com/a/22908437/1120530; Using --relative as --rsync-path not working
    mkdir -p minishift-centos-iso/master/$BUILD_NUMBER/
    cp build/* minishift-centos-iso/master/$BUILD_NUMBER/
    RSYNC_PASSWORD=$1 rsync -a --relative minishift-centos-iso/master/$BUILD_NUMBER/ minishift@artifacts.ci.centos.org::minishift/
    echo "Find Artifacts here http://artifacts.ci.centos.org/${REPO_OWNER}/${REPO_NAME}/master/$BUILD_NUMBER ."
  else
    # http://stackoverflow.com/a/22908437/1120530; Using --relative as --rsync-path not working
    mkdir -p minishift-centos-iso/pr/$ghprbPullId/
    cp build/* minishift-centos-iso/pr/$ghprbPullId/
    RSYNC_PASSWORD=$1 rsync -a --relative minishift-centos-iso/pr/$ghprbPullId/ minishift@artifacts.ci.centos.org::minishift/
    echo "Find Artifacts here http://artifacts.ci.centos.org/${REPO_OWNER}/${REPO_NAME}/pr/$ghprbPullId ."
  fi
}

function create_release_commit() {
  # Create master branch as git clone in CI doesn't create it
  git checkout -b master
  # Bump version and commit
  sed -i "s|VERSION=.*|VERSION=$RELEASE_VERSION|" Makefile
  git add Makefile
  git commit -m "cut v$RELEASE_VERSION"
  git push https://$REPO_OWNER:$GITHUB_TOKEN@github.com/$REPO_OWNER/$REPO_NAME master
}

function add_release_notes() {
  release_id=$(curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases" | jq --arg release "v$RELEASE_VERSION" -r ' .[] | if .name == $release then .id else empty end')

  if [[ "$release_id" != "" ]]; then
    MILESTONE_ID=`curl -s https://api.github.com/repos/minishift/${REPO_NAME}/milestones?state=all  | jq --arg version "v$RELEASE_VERSION" -r ' .[] | if .title == $version then .number else empty end'`

    if [[ "$MILESTONE_ID" != "" ]]; then
      # Generate required json payload for release note
      ./scripts/release/issue-list.sh -r $REPO_NAME -m $MILESTONE_ID | jq -Rn 'inputs + "\n"' | jq -s '{body:  add }' > json_payload.json
      # Add release notes
      curl -H "Content-Type: application/json" -H "Authorization: token $GITHUB_TOKEN" \
           --data @json_payload.json https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/$release_id

      echo "Release notes of Minishift CentOS ISO v$RELEASE_VERSION has been successfully updated. Find the release notes here https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/tag/v$RELEASE_VERSION."
    else
      echo "Failed to get milestone ID for Minishift CentOS ISO v$RELEASE_VERSION. Use manual approach to update the release notes here https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/tag/v$RELEASE_VERSION."
    fi
  else
    return 1
  fi
}

function perform_release() {
  create_release_commit
  exit_on_failure "$?" "Unable to create release commit."

  make release
  exit_on_failure "$?" "Failed to release Minishift CentOS ISO v$RELEASE_VERSION. Try to release manually."
  echo "Minishift CentOS ISO v$RELEASE_VERSION has been successfully released. Find the latest release here https://github.com/$REPO_OWNER/$REPO_NAME/releases/tag/v$RELEASE_VERSION."

  add_release_notes;
  exit_on_failure "$?" "Failed to update release notes of Minishift CentOS ISO v$RELEASE_VERSION. Try to manually update the release notes here - https://github.com/$REPO_OWNER/$REPO_NAME/releases/tag/v$RELEASE_VERSION."
}

# Execution starts here
load_jenkins_vars
install_required_packages
start_libvirt
setup_kvm_machine_driver

# Set Terminal
export TERM=xterm-256color
# Add git a/c identity
git config --global user.email "29732253+minishift-bot@users.noreply.github.com"
git config --global user.name "Minishift Bot"

# Build ISO and test
make centos_iso
make test

# Retrieve password for rsync
CICO_PASS=$(echo $CICO_API_KEY | cut -d'-' -f1-2)
# Export GITHUB_ACCESS_TOKEN to prevent Github rate limit and push to master during release job
export GITHUB_ACCESS_TOKEN=$GITHUB_TOKEN

if [[ "$JOB_NAME" = "minishift-centos-iso-release" ]]; then
  perform_release
else
  # Runs for both PR and master jobs
  perform_artifacts_upload $CICO_PASS
fi
