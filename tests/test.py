import time
import logging
import os
import subprocess

from avocado import VERSION
from avocado import Test

class MinishiftISOTest(Test):

    def setUp(self):
        ''' Test Setup '''
        self.test_DIR = os.path.dirname(os.path.realpath(__file__))
        self.log.info("################################################################")
        self.log.info("Avocado version : %s" % VERSION)
        self.log.info("################################################################")

    def test_minishift_centos_iso_file(self):
        ''' minishift centos iso file existence test '''
        self.log.info("Testing minishift centos iso file existence ...")
        iso_file = "%s/../build/minishift-centos.iso" % self.test_DIR
        self.assertTrue(os.path.isfile(iso_file))
