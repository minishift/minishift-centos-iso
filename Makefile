BUILD_DIR=$(shell pwd)/build
HANDLE_USER_DATA=$(shell base64 -w 0 scripts/handle-user-data)
CERT_GEN=$(shell base64 -w 0 scripts/cert-gen.sh)

default: centos_iso

.PHONY: init
init:
	mkdir -p $(BUILD_DIR)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

.PHONY: iso
iso_creation: init
	handle_user_data='$(HANDLE_USER_DATA)' cert_gen='$(CERT_GEN)' envsubst < $(KICKSTART_TEMPLATE) > $(BUILD_DIR)/$(KICKSTART_FILE)
	cd $(BUILD_DIR); sudo livecd-creator --config $(BUILD_DIR)/$(KICKSTART_FILE) --logfile=$(BUILD_DIR)/livecd-creator.log --fslabel $(ISO_NAME)

.PHONY: centos_iso
centos_iso: KICKSTART_FILE=centos-7-minimal.ks
centos_iso: KICKSTART_TEMPLATE=centos-7-minimal.template
centos_iso: ISO_NAME=minishift-centos.iso
centos_iso: iso_creation

.PHONY: rhel_iso
rhel_iso: KICKSTART_FILE=rhel-7-minimal.ks
rhel_iso: KICKSTART_TEMPLATE=rhel-7-minimal.template
rhel_iso: ISO_NAME=minishift-rhel.iso
rhel_iso: iso_creation
