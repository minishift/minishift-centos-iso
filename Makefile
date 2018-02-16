BUILD_DIR=$(shell pwd)/build
BIN_DIR=$(BUILD_DIR)/bin
HANDLE_USER_DATA=$(shell base64 -w 0 scripts/handle-user-data)
HANDLE_USER_DATA_SERVICE=$(shell base64 -w 0 scripts/handle-user-data.service)
YUM_WRAPPER=$(shell base64 -w 0 scripts/yum-wrapper)
CERT_GEN=$(shell base64 -w 0 scripts/cert-gen)
SET_IPADDRESS=$(shell base64 -w 0 scripts/set-ipaddress)
SET_IPADDRESS_SERVICE=$(shell base64 -w 0 scripts/set-ipaddress.service)
VERSION=1.6.1
GITTAG=$(shell git rev-parse --short HEAD)
TODAY=$(shell date +"%d%m%Y%H%M%S")
MINISHIFT_LATEST_URL=$(shell python tests/utils/minishift_latest_version.py)
ARCHIVE_FILE=$(shell echo $(MINISHIFT_LATEST_URL) | rev | cut -d/ -f1 | rev)
MINISHIFT_UNTAR_DIR=$(shell echo $(ARCHIVE_FILE) | sed 's/.tgz//')

ifndef BUILD_ID
    BUILD_ID=local
endif

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
	@if test "$(rhel_tree_url)" = ""; then \
		echo "rhel_tree_url is undefined, Please check README"; \
		exit 1; \
	elif test "$(base_repo_url)" = ""; then \
		echo "base_repo_url is undefined, Please check README"; \
		exit 1; \
	elif test "$(updates_repo_url)" = ""; then \
		echo "updates_repo_url is undefined, Please check README"; \
		exit 1; \
	elif test "$(cdk_repo_url)" = ""; then \
		echo "cdk_repo_url is undefined, Please check README"; \
		exit 1; \
	fi

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




# INTEGRATION TESTS
REPOPATH ?= github.com/minishift/minishift-centos-iso
TEST_DIR ?= $(CURDIR)/testing
INTEGRATION_TEST_DIR = $(TEST_DIR)/integration-test

# Platfrom dependency
ifeq ($(GOOS),windows)
	IS_EXE := .exe
endif

# Integration tests
TIMEOUT ?= 3600s
MINISHIFT_BINARY ?= $(TEST_DIR)/bin/minishift$(IS_EXE)

# Make target definitions
.PHONY: integration
integration:
	mkdir -p $(INTEGRATION_TEST_DIR)
	MINISHIFT_ISO_URL=file://$(TEST_DIR)/iso/minishift-centos7.iso go test -timeout $(TIMEOUT) $(REPOPATH)/tests/integration --tags=integration -v -args --test-dir $(INTEGRATION_TEST_DIR) --binary $(MINISHIFT_BINARY) \
	--run-before-feature="$(RUN_BEFORE_FEATURE)" --test-with-specified-shell="$(TEST_WITH_SPECIFIED_SHELL)" --tags=$(ADDON) $(GODOG_OPTS)

.PHONY: vendor
vendor:
	dep ensure -v

