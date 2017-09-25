function exit_with_message() {
  if [[ "$1" != 0 ]]; then
    echo "$2"
    exit 1
  fi
}

build/bin/minishift start --iso-url file:///root/payload/build/minishift-centos7.iso --show-libmachine-logs
exit_with_message "$?" "Error starting Minishift VM"
echo "=============================================="
build/bin/minishift status
exit_with_message "$?" "Error getting status"
build/bin/minishift stop
exit_with_message "$?" "Error stopping VM"
echo "=============================================="
build/bin/minishift status
exit_with_message "$?" "Error getting status"
echo "=============================================="
build/bin/minishift start --iso-url file:///root/payload/build/minishift-centos7.iso --show-libmachine-logs
exit_with_message "$?" "Error starting Minishift VM"
echo "=============================================="
build/bin/minishift ssh -- echo hello
exit_with_message "$?" "Error ssh into VM"
build/bin/minishift ip
exit_with_message "$?" "Error getting IP"
build/bin/minishift docker-env
exit_with_message "$?" "Error displaying docker-env"
build/bin/minishift ssh -- sudo /sbin/mount.cifs -V
exit_with_message "$?" "Error in /sbin/mount.cifs -V"
build/bin/minishift ssh -- sudo sshfs -V
exit_with_message "$?" "Error in sshfs -V"
build/bin/minishift ssh -- sudo /sbin/mount.nfs -V
exit_with_message "$?" "Error in /sbin/mount.nfs -V"
build/bin/minishift status
exit_with_message "$?" "Error getting status"
