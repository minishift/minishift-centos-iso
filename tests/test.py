import glob
import os
import re
import subprocess
import sys
import time
import shutil
import socket

from avocado import VERSION
from avocado import Test

class MinishiftISOTest(Test):

    def setUp(self):
        ''' Test Setup '''
        self.log.info("################################################################")
        self.log.info("Avocado version : %s" % VERSION)
        self.log.info("################################################################")

        self.repo_dir = os.path.dirname(os.path.realpath(__file__)) + "/.."
        self.scripts_dir = self.repo_dir + "/tests/"
        self.bin_dir = self.repo_dir + "/build/bin/"
        self.driver_name = 'kvm'
        self.iso_name = 'minishift-centos7'

        # Find iso files and skip test if no ISO file is found
        self.iso_file = self.repo_dir + "/build/%s.iso" % self.iso_name
        if not os.path.isfile(self.iso_file):
            self.skip("Skipping testing as no ISO found in 'build' directory.")

    def test_boot_vm_out_of_iso(self):
        ''' Test booting up VM out of ISO '''
        start_args = (self.driver_name, "file://"  + self.iso_file)
        cmd = self.bin_dir + "minishift start --vm-driver %s --iso-url %s" % start_args
        self.execute_test({ 'cmd': cmd })

    def test_ssh_connection_to_vm(self):
        ''' Test SSH connection to the VM '''
        cmd = self.bin_dir + "minishift ssh exit"
        self.execute_test({ 'cmd': cmd })

    def test_ip_of_vm(self):
        ''' Test IP of the VM '''
        cmd = self.bin_dir + "minishift ip"
        output = self.execute_test({ 'cmd': cmd })

        # Verify IP
        try:
            socket.inet_aton(output)
        except socket.error:
            self.fail("Error in getting IP with minishift VM.")

    def test_docker_env_evaluable(self):
        cmd = self.bin_dir + "minishift docker-env"
        output = self.execute_test({ 'cmd': cmd })
        self.check_data_evaluable(output.rstrip())

    def test_cifs_installed(self):
        cmd = self.bin_dir + "minishift ssh 'sudo /sbin/mount.cifs -V'"
        output = self.execute_test({ 'cmd': cmd })
        self.assertEqual(output.rstrip(), 'mount.cifs version: 6.2')

    def test_sshfs_installed(self):
        cmd = self.bin_dir + "minishift ssh 'sudo sshfs -V'"
        output = self.execute_test({ 'cmd': cmd })
        self.assertRegexpMatches(output.rstrip(), r'.*SSHFS version 2\.5.*')

    def test_nfs_installed(self):
        cmd = self.bin_dir + "minishift ssh 'sudo /sbin/mount.nfs -V'"
        output = self.execute_test({ 'cmd': cmd })
        self.assertEqual(output.rstrip(), 'mount.nfs: (linux nfs-utils 1.3.0)')

    def test_stopping_vm(self):
        ''' Test stopping machine '''
        cmd = self.bin_dir + "minishift stop"
        self.execute_test({ 'cmd': cmd })

        # Check VM status status
        cmd = self.bin_dir + "minishift status"
        self.log.info("Executing command : %s" % cmd)
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        output = process.communicate()[0]
        self.assertEqual(0, process.returncode)
        self.assertEqual('Stopped', output.rstrip())

    def test_swapspace(self):
        ''' Test if swap space is available on restart '''
        start_args = (self.driver_name, "file://"  + self.iso_file)
        cmd = self.bin_dir + "minishift start --vm-driver %s --iso-url %s" % start_args
        self.execute_test({ 'cmd': cmd })

        # Check swap space
        cmd = self.bin_dir + "minishift ssh \"echo `free | tail -n 1 | awk '{print $2}'`\""
        self.log.info("Executing command : %s" % cmd)
        output = self.execute_test({ 'cmd': cmd })
        self.assertNotEqual(0, output)

    def test_delete_vm(self):
        ''' Test removing machine '''
        cmd = self.bin_dir + "minishift delete"
        self.execute_test({ 'cmd': cmd })

        # Check VM status status
        cmd = self.bin_dir + "minishift status"
        self.log.info("Executing command : %s" % cmd)
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        output = process.communicate()[0]
        self.assertEqual(0, process.returncode)
        self.assertEqual('Does Not Exist', output.rstrip())

    # Helper Functions
    def execute_test(self, options):
        cmd = options['cmd']
        self.log.info("\n*******\nExecuting command : %s\n*******" % cmd)
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        output, error_message = process.communicate()
        if error_message:
            self.log.debug("Error: %s" % error_message)

        self.assertEqual(0, process.returncode)
        return output

    def check_data_evaluable(self, data):
        for line in data.splitlines():
            REGEX = re.compile('^#.*|^export [a-zA-Z_]+=.*|^\n')
            self.assertTrue(REGEX.match(line))
