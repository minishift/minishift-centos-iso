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

.PHONY: centos_iso
centos_iso: KICKSTART_FILE=centos-7.ks
centos_iso: KICKSTART_TEMPLATE=centos-7.template
centos_iso: ISO_NAME=minishift-centos
centos_iso: iso_creation

.PHONY: rhel_iso
rhel_iso: KICKSTART_FILE=rhel-7.ks
rhel_iso: KICKSTART_TEMPLATE=rhel-7.template
rhel_iso: ISO_NAME=minishift-rhel
rhel_iso: check_env
rhel_iso: iso_creation

.PHONY: iso
iso_creation: init
	handle_user_data='$(HANDLE_USER_DATA)' cert_gen='$(CERT_GEN)' envsubst < $(KICKSTART_TEMPLATE) > $(BUILD_DIR)/$(KICKSTART_FILE)
	cd $(BUILD_DIR); sudo livecd-creator --config $(BUILD_DIR)/$(KICKSTART_FILE) --logfile=$(BUILD_DIR)/livecd-creator.log --fslabel $(ISO_NAME)
	# http://askubuntu.com/questions/153833/why-cant-i-mount-the-ubuntu-12-04-installer-isos-in-mac-os-x
	# http://www.syslinux.org/wiki/index.php?title=Doc/isolinux#HYBRID_CD-ROM.2FHARD_DISK_MODE
	dd if=/dev/zero bs=2k count=1 of=${BUILD_DIR}/tmp.iso
	dd if=$(BUILD_DIR)/$(ISO_NAME).iso bs=2k skip=1 >> ${BUILD_DIR}/tmp.iso
	mv -f ${BUILD_DIR}/tmp.iso $(BUILD_DIR)/$(ISO_NAME).iso

.PHONY: check
check_env:
	if test "$(rhel_tree_url)" = ""; then \
		echo "rhel_tree_url is undefined, Please check README"; \
		exit 1; \
	elif test "$(base_repo_url)" = ""; then \
		echo "base_repo_url is undefined, Please check README"; \
		exit 1; \
	elif test "$(updates_repo_url)" = ""; then \
		echo "updates_repo_url is undefined, Please check README"; \
		exit 1; \
	fi
