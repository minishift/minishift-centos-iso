BUILD_DIR=$(shell pwd)/build
BIN_DIR=$(BUILD_DIR)/bin
HANDLE_USER_DATA=$(shell base64 -w 0 scripts/handle-user-data)
HANDLE_USER_DATA_SERVICE=$(shell base64 -w 0 scripts/handle-user-data.service)
YUM_WRAPPER=$(shell base64 -w 0 scripts/yum-wrapper)
CERT_GEN=$(shell base64 -w 0 scripts/cert-gen)
SET_IPADDRESS=$(shell base64 -w 0 scripts/set-ipaddress)
SET_IPADDRESS_SERVICE=$(shell base64 -w 0 scripts/set-ipaddress.service)
VERSION=1.15.0
GITTAG=$(shell git rev-parse --short HEAD)
TODAY=$(shell date +"%d%m%Y%H%M%S")
MINISHIFT_LATEST_URL=$(shell python tests/utils/minishift_latest_version.py)
ARCHIVE_FILE=$(shell echo $(MINISHIFT_LATEST_URL) | rev | cut -d/ -f1 | rev)
MINISHIFT_UNTAR_DIR=$(shell echo $(ARCHIVE_FILE) | sed 's/.tgz//')

ifndef BUILD_ID
    BUILD_ID=local
endif

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

default: centos_iso

.PHONY: init
init:
	mkdir -p $(BUILD_DIR)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)



.PHONY: centos_iso
centos_iso: ISO_NAME=minishift-centos7
centos_iso: KICKSTART_FILE=centos-7.ks
centos_iso: centos_kickstart
centos_iso: iso_creation

.PHONY: rhel_iso
rhel_iso: ISO_NAME=minishift-rhel7
rhel_iso: KICKSTART_FILE=rhel-7.ks
rhel_iso: rhel_kickstart
rhel_iso: iso_creation

.PHONY: centos_kickstart
centos_kickstart: KICKSTART_FILE=centos-7.ks
centos_kickstart: KICKSTART_TEMPLATE=centos-7.template
centos_kickstart: kickstart

.PHONY: rhel_kickstart
rhel_kickstart: KICKSTART_FILE=rhel-7.ks
rhel_kickstart: KICKSTART_TEMPLATE=rhel-7.template
rhel_kickstart: check_env
rhel_kickstart: kickstart

.PHONY: kickstart
kickstart: init
	@handle_user_data='$(HANDLE_USER_DATA)' handle_user_data_service='$(HANDLE_USER_DATA_SERVICE)' \
        set_ipaddress='$(SET_IPADDRESS)' set_ipaddress_service='$(SET_IPADDRESS_SERVICE)' \
        yum_wrapper='$(YUM_WRAPPER)' cert_gen='$(CERT_GEN)' \
		version='$(VERSION)' build_id='$(GITTAG)-$(TODAY)-$(BUILD_ID)' \
		envsubst < $(KICKSTART_TEMPLATE) > $(BUILD_DIR)/$(KICKSTART_FILE)

.PHONY: iso_creation
iso_creation:
	cd $(BUILD_DIR); sudo livecd-creator --config $(BUILD_DIR)/$(KICKSTART_FILE) --logfile=$(BUILD_DIR)/livecd-creator.log --fslabel $(ISO_NAME)
	# http://askubuntu.com/questions/153833/why-cant-i-mount-the-ubuntu-12-04-installer-isos-in-mac-os-x
	# http://www.syslinux.org/wiki/index.php?title=Doc/isolinux#HYBRID_CD-ROM.2FHARD_DISK_MODE
	dd if=/dev/zero bs=2k count=1 of=${BUILD_DIR}/tmp.iso
	dd if=$(BUILD_DIR)/$(ISO_NAME).iso bs=2k skip=1 >> ${BUILD_DIR}/tmp.iso
	mv -f ${BUILD_DIR}/tmp.iso $(BUILD_DIR)/$(ISO_NAME).iso

.PHONY: check_env
check_env:
	$(call check_defined, rhel_tree_url, "rhel_tree_url is undefined. Please check README.")
	$(call check_defined, base_repo_url, "base_repo_url is undefined. Please check README.")
	$(call check_defined, updates_repo_url, "updates_repo_url is undefined. Please check README.")
	$(call check_defined, cdk_repo_url, "cdk_repo_url is undefined. Please check README.")

.PHONY: get_gh-release
get_gh-release: init
	curl -sL https://github.com/progrium/gh-release/releases/download/v2.2.1/gh-release_2.2.1_linux_x86_64.tgz > $(BUILD_DIR)/gh-release_2.2.1_linux_x86_64.tgz
	tar -xvf $(BUILD_DIR)/gh-release_2.2.1_linux_x86_64.tgz -C $(BUILD_DIR)
	rm -fr $(BUILD_DIR)/gh-release_2.2.1_linux_x86_64.tgz

.PHONY: release
release: centos_iso get_gh-release
	rm -rf release && mkdir -p release
	cp $(BUILD_DIR)/minishift-centos7.iso release/
	$(BUILD_DIR)/gh-release checksums sha256
	$(BUILD_DIR)/gh-release create minishift/minishift-centos-iso $(VERSION) master v$(VERSION)

$(BIN_DIR)/minishift:
	@echo "Downloading latest minishift binary at $(BIN_DIR)/minishift..."
	@mkdir -p $(BIN_DIR)
	@cd $(BIN_DIR) && \
	curl -LO --progress-bar $(MINISHIFT_LATEST_URL) && \
	tar xzf $(ARCHIVE_FILE) && \
	mv $(MINISHIFT_UNTAR_DIR)/minishift .
	@echo "Done."

.PHONY: test
test: $(BIN_DIR)/minishift
	sh tests/test.sh

.PHONY: ci_release
ci_release:
	$(call check_defined, API_KEY, "To trigger the CentOS CI release build you need to specify the CentOS CI API key.")
	$(call check_defined, RELEASE_VERSION, "You need to specify the version you want to release.")

	curl -s -H "$(shell curl -s --user 'minishift:$(API_KEY)' 'https://ci.centos.org//crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')" \
	-X POST https://ci.centos.org/job/minishift-centos-iso-release/build --user 'minishift:$(API_KEY)' \
	--data-urlencode json='{"parameter": [{"name":"RELEASE_VERSION", "value":'"$(RELEASE_VERSION)"'}]}'
