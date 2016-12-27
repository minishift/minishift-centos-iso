BUILD_DIR=$(shell pwd)/build
HANDLE_USER_DATA=$(shell base64 -w 0 scripts/handle-user-data)
CERT_GEN=$(shell base64 -w 0 scripts/cert-gen.sh)
VERSION=1.0.0-alpha.1
GITTAG=$(shell git rev-parse --short HEAD)
TODAY=$(shell date +"%d%m%Y%H%M%S")
ifndef BUILD_ID
    BUILD_ID=local
endif

default: centos_iso

init:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

centos_iso: KICKSTART_FILE=centos-7.ks
centos_iso: KICKSTART_TEMPLATE=centos-7.template
centos_iso: ISO_NAME=minishift-centos
centos_iso: iso_creation

rhel_iso: KICKSTART_FILE=rhel-7.ks
rhel_iso: KICKSTART_TEMPLATE=rhel-7.template
rhel_iso: ISO_NAME=minishift-rhel
rhel_iso: check_env
rhel_iso: iso_creation

iso_creation: init
	handle_user_data='$(HANDLE_USER_DATA)' cert_gen='$(CERT_GEN)' version='$(VERSION)' build_id='$(GITTAG)-$(TODAY)-$(BUILD_ID)' \
			 envsubst < $(KICKSTART_TEMPLATE) > $(BUILD_DIR)/$(KICKSTART_FILE)
	cd $(BUILD_DIR); sudo livecd-creator --config $(BUILD_DIR)/$(KICKSTART_FILE) --logfile=$(BUILD_DIR)/livecd-creator.log --fslabel $(ISO_NAME)
	# http://askubuntu.com/questions/153833/why-cant-i-mount-the-ubuntu-12-04-installer-isos-in-mac-os-x
	# http://www.syslinux.org/wiki/index.php?title=Doc/isolinux#HYBRID_CD-ROM.2FHARD_DISK_MODE
	dd if=/dev/zero bs=2k count=1 of=${BUILD_DIR}/tmp.iso
	dd if=$(BUILD_DIR)/$(ISO_NAME).iso bs=2k skip=1 >> ${BUILD_DIR}/tmp.iso
	mv -f ${BUILD_DIR}/tmp.iso $(BUILD_DIR)/$(ISO_NAME).iso

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

get_gh-release: init
	curl -sL https://github.com/progrium/gh-release/releases/download/v2.2.1/gh-release_2.2.1_linux_x86_64.tgz > $(BUILD_DIR)/gh-release_2.2.1_linux_x86_64.tgz
	tar -xvf $(BUILD_DIR)/gh-release_2.2.1_linux_x86_64.tgz -C $(BUILD_DIR)
	rm -fr $(BUILD_DIR)/gh-release_2.2.1_linux_x86_64.tgz

release: centos_iso get_gh-release
	rm -rf release && mkdir -p release
	cp $(BUILD_DIR)/minishift-centos.iso release/
	$(BUILD_DIR)/gh-release checksums sha256
	$(BUILD_DIR)/gh-release create minishift/minishift-centos-iso $(VERSION) master v$(VERSION)

.PHONY: init clean centos_iso rhel_iso iso_creation check_env get_gh-release release
