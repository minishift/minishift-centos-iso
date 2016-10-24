CENTOS_KICKSTART_FILE=centos-7-minimal.ks
CENTOS_KICKSTART_TEMPLATE=centos-7-minimal.template

RHEL_KICKSTART_FILE=rhel-7-minimal.ks
RHEL_KICKSTART_TEMPLATE=rhel-7-minimal.template

CENTOS_ISO_NAME=live-centos
RHEL_ISO_NAME=live-rhel

BUILD_DIR=$(shell pwd)/build

HANDLE_USER_DATA=$(shell base64 -w 0 scripts/handle-user-data)
CERT_GEN=$(shell base64 -w 0 scripts/cert-gen.sh)

default: centos_iso

kickstart:
	mkdir -p $(BUILD_DIR)

iso_creation: kickstart
	handle_user_data='$(HANDLE_USER_DATA)' cert_gen='$(CERT_GEN)' envsubst < $(KICKSTART_TEMPLATE) > $(BUILD_DIR)/$(KICKSTART_FILE)
	cd $(BUILD_DIR); sudo livecd-creator --config $(BUILD_DIR)/$(KICKSTART_FILE) --logfile=$(BUILD_DIR)/livecd-creator.log --fslabel $(ISO_NAME)

centos_iso: KICKSTART_FILE=$(CENTOS_KICKSTART_FILE)
centos_iso: KICKSTART_TEMPLATE=$(CENTOS_KICKSTART_TEMPLATE)
centos_iso: ISO_NAME=$(CENTOS_ISO_NAME)
centos_iso: iso_creation

rhel_iso: KICKSTART_FILE=$(RHEL_KICKSTART_FILE)
rhel_iso: KICKSTART_TEMPLATE=$(RHEL_KICKSTART_TEMPLATE)
rhel_iso: ISO_NAME=$(RHEL_ISO_NAME)
rhel_iso: iso_creation

clean:
	rm -rf $(BUILD_DIR)
