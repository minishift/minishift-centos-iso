#!/bin/bash

# Output command before executing
set -x

# Exit on error
set -e

# Source environment variables of the jenkins slave
# that might interest this worker.
if [ -e "jenkins-env" ]; then
  cat jenkins-env \
    | grep -E "(JENKINS_URL|GIT_BRANCH|GIT_COMMIT|BUILD_NUMBER|ghprbSourceBranch|ghprbActualCommit|BUILD_URL|ghprbPullId|CICO_API_KEY)=" \
    | sed 's/^/export /g' \
    > ~/.jenkins-env
  source ~/.jenkins-env
fi

# Get all the deps in
yum -y install \
  make \
  git \
  epel-release \
  livecd-tools \
  curl \
  docker \
  parted \
  kvm \
  qemu-kvm \
  libvirt

# Start Libvirt
sudo systemctl start libvirtd

# Install Avocado
sudo curl https://repos-avocadoproject.rhcloud.com/static/avocado-el.repo -o /etc/yum.repos.d/avocado.repo
sudo yum install -y avocado

# Setup test drivers
curl -L https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.7.0/docker-machine-driver-kvm > /usr/local/bin/docker-machine-driver-kvm && \
chmod +x /usr/local/bin/docker-machine-driver-kvm

# Prepare ISO for testing
make centos_iso

# Let's test with showing log enabled
SHOW_LOG=--show-job-log make test

# On reaching successfully at this point, upload artifacts
PASS=$(echo $CICO_API_KEY | cut -d'-' -f1-2)

rm -rf build/bin # Don't upload bin folder
set +x
# For PR build, GIT_BRANCH is set to branch name other than origin/master
if [[ "$GIT_BRANCH" = "origin/master" ]]; then
  # http://stackoverflow.com/a/22908437/1120530; Using --relative as --rsync-path not working
  mkdir -p minishift-centos-iso/master/$BUILD_NUMBER/
  cp build/* minishift-centos-iso/master/$BUILD_NUMBER/
  RSYNC_PASSWORD=$PASS rsync -a --relative minishift-centos-iso/master/$BUILD_NUMBER/ minishift@artifacts.ci.centos.org::minishift/
  echo "Find Artifacts here http://artifacts.ci.centos.org/minishift/minishift-centos-iso/master/$BUILD_NUMBER ."
else
  # http://stackoverflow.com/a/22908437/1120530; Using --relative as --rsync-path not working
  mkdir -p minishift-centos-iso/pr/$ghprbPullId/
  cp build/* minishift-centos-iso/pr/$ghprbPullId/
  RSYNC_PASSWORD=$PASS rsync -a --relative minishift-centos-iso/pr/$ghprbPullId/ minishift@artifacts.ci.centos.org::minishift/
  echo "Find Artifacts here http://artifacts.ci.centos.org/minishift/minishift-centos-iso/pr/$ghprbPullId ."
fi
