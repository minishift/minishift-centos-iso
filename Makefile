KICKSTART_FILE=centos-7-minimal.ks
KICKSTART_TEMPLATE=centos-7-minimal.template

BUILD_DIR=$(shell pwd)/build
ISO_NAME=live-centos

HANDLE_USER_DATA=$(shell base64 -w 0 scripts/handle-user-data)
CERT_GEN=$(shell base64 -w 0 scripts/cert-gen.sh)

default: iso

kickstart:
	mkdir -p $(BUILD_DIR)
	touch $(BUILD_DIR)/$(KICKSTART_FILE)
	handle_user_data='$(HANDLE_USER_DATA)' cert_gen='$(CERT_GEN)' envsubst <  $(KICKSTART_TEMPLATE) > $(BUILD_DIR)/$(KICKSTART_FILE)

iso: kickstart
	cd $(BUILD_DIR); sudo livecd-creator --config $(BUILD_DIR)/$(KICKSTART_FILE) --logfile=$(BUILD_DIR)/livecd-creator.log --fslabel $(ISO_NAME)

clean:
	rm -rf $(BUILD_DIR)
