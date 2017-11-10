#!/bin/sh

BINARY=build/bin/minishift
ISO=file://$(pwd)/build/minishift-centos7.iso
EXTRA_FLAGS="--show-libmachine-logs"

function print_success_message() {
  echo ""
  echo " ------------ [ $1 - Passed ]"
  echo ""
}

function exit_with_message() {
  if [[ "$1" != 0 ]]; then
    echo "$2"
    exit 1
  fi
}

function assert_equal() {
  if [ "$1" != "$2" ]; then
    echo "Expected '$2' but got '$1'"
    exit 1
  fi
}

# http://www.linuxjournal.com/content/validating-ip-address-bash-script
function assert_valid_ip() {
  local ip=$1
  local valid=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
    && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    valid=$?
  fi

  if [[ "$valid" != 0 ]]; then
    echo "IP '$1' is invalid"
    exit 1
  fi
 }

function verify_start_instance() {
  $BINARY start --iso-url $ISO $EXTRA_FLAGS
  exit_with_message "$?" "Error starting Minishift VM"
  output=`$BINARY status | sed -n 1p`
  assert_equal "$output" "Minishift:  Running"
  print_success_message "Starting VM"
}

function verify_stop_instance() {
  $BINARY stop
  exit_with_message "$?" "Error starting Minishift VM"
  output=`$BINARY status | sed -n 1p`
  assert_equal "$output" "Minishift:  Stopped"
  print_success_message "Stopping VM"
}

function verify_swap_space() {
  output=`$BINARY ssh -- echo $(free | tail -n 1 | awk '{print $2}')`
  if [ "$output" == "0" ]; then
    echo "Expected '0' but got '$output'"
    exit 1
  fi
  print_success_message "Swap space check"
}

function verify_ssh_connection() {
  output=`$BINARY ssh -- echo hello`
  assert_equal "$output" "hello"
  print_success_message "SSH Connection"
}

function verify_vm_ip() {
  output=`$BINARY ip`
  assert_valid_ip $output
  print_success_message "Getting VM IP"
}

function verify_cifs_installation() {
  expected="mount.cifs version: 6.2"
  output=`$BINARY ssh -- sudo /sbin/mount.cifs -V`
  assert_equal "$output" "$expected"
  print_success_message "CIFS installation"
}

function verify_sshfs_installation() {
  expected="SSHFS version 2.5"
  output=`$BINARY ssh -- sudo sshfs -V`
  echo $output | grep "$expected" > /dev/null
  if [ "$?" != "0" ]; then
    echo "Expected exit status of command '$BINARY ssh -- sudo sshfs -V' to be 0."
    exit 1
  fi
  print_success_message "SSHFS installation"
}

function verify_nfs_installation() {
  expected="mount.nfs: (linux nfs-utils 1.3.0)"
  output=`$BINARY ssh -- sudo /sbin/mount.nfs -V /need/for/version`
  assert_equal "$output" "$expected"
  print_success_message "NFS installation"
}

function verify_bind_mount() {
  output=`$BINARY ssh -- 'findmnt | grep "\[/var/lib/" | wc -l'`
  assert_equal $output "4"
  print_success_message "Bind mount check"
}

function verify_hvkvp_installation() {
  expected="Error opening pool"
  output=`$BINARY ssh -- 'hvkvp'`
  assert_equal "$output" "$expected"
  print_success_message "HVKVP check"
}

function verify_delete() {
  $BINARY delete --force
  exit_with_message "$?" "Error deleting Minishift VM"
}

# Tests
verify_start_instance
sleep 90
verify_stop_instance
verify_start_instance
verify_swap_space
verify_vm_ip
verify_cifs_installation
verify_sshfs_installation
verify_nfs_installation
verify_bind_mount
verify_delete
