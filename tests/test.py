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
        self.bin_dir = self.repo_dir + "/bin/"
        self.docker_machine_vm = "docker-machine-test-vm"
        self.iso_name = 'minishift-centos'

        # Find iso files and skip test if no ISO file is found
        self.iso_file = self.repo_dir + "/build/%s.iso" % self.iso_name
        if not os.path.isfile(self.iso_file):
            self.skip("Skipping testing as no ISO found in 'build' directory.")

    def test_boot_vm_out_of_iso(self):
        ''' Test booting up VM out of ISO '''
        cmd = self.bin_dir + "docker-machine create %s -d kvm --kvm-boot2docker-url=%s" % (self.docker_machine_vm, self.iso_file)
        self.execute_test({ 'cmd': cmd })
        # TODO: Minishift

    def test_ssh_connection_to_vm(self):
        ''' Test SSH connection to the VM '''
        cmd = self.bin_dir + "docker-machine ssh %s exit" % self.docker_machine_vm
        self.execute_test({ 'cmd': cmd })

    def test_ip_of_vm(self):
        ''' Test IP of the VM '''
        cmd = self.bin_dir + "docker-machine ip %s" % self.docker_machine_vm
        output = self.execute_test({ 'cmd': cmd })

        # Verify IP
        try:
            socket.inet_aton(output)
        except socket.error:
            self.fail("Error in getting IP with docker-machine.")

    def test_docker_env_evaluable(self):
        cmd = self.bin_dir + "docker-machine env %s" % self.docker_machine_vm
        output = self.execute_test({ 'cmd': cmd })
        self.check_data_evaluable(output.rstrip())

    def test_stopping_vm(self):
        ''' Test stopping machine '''
        cmd = self.bin_dir + "docker-machine stop %s" % self.docker_machine_vm
        self.execute_test({ 'cmd': cmd })

        # Check VM status status
        cmd = self.bin_dir + "docker-machine status %s" % self.docker_machine_vm
        self.log.info("Executing command : %s" % cmd)
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        output = process.communicate()[0]
        self.assertEqual(0, process.returncode)
        self.assertEqual('Stopped', output.rstrip())

    def test_removing_vm(self):
        ''' Test removing machine '''
        cmd = self.bin_dir + "docker-machine rm -f %s" % self.docker_machine_vm
        self.execute_test({ 'cmd': cmd })

        # Check VM status status
        cmd = self.bin_dir + "docker-machine status %s" % self.docker_machine_vm
        self.log.info("Executing command : %s" % cmd)
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        error_message = process.communicate()[1]
        self.assertEqual(1, process.returncode)
        self.assertEqual('Host does not exist: "%s"' % self.docker_machine_vm, error_message.rstrip())

    # Helper Functions
    def execute_test(self, options):
        cmd = options['cmd']
        self.log.info("Executing command : %s" % cmd)
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
