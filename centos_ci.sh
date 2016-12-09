#!/bin/bash

# Output command before executing
set -x

# Exit on error
set -e

# Source environment variables of the jenkins slave
# that might interest this worker.
if [ -e "jenkins-env" ]; then
  cat jenkins-env \
    | grep -E "(JENKINS_URL|GIT_BRANCH|GIT_COMMIT|BUILD_NUMBER|ghprbSourceBranch|ghprbActualCommit|BUILD_URL|ghprbPullId)=" \
    | sed 's/^/export /g' \
    > ~/.jenkins-env
  source ~/.jenkins-env
fi

# We need to disable selinux for now, XXX
/usr/sbin/setenforce 0

# Get all the deps in
yum -y install \
  make \
  git \
  epel-release \
  livecd-tools \
  curl

# Install Libvirt
sudo yum -y install kvm qemu-kvm libvirt
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
