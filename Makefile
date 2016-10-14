KICKSTART_FILE=centos-7-minimal.ks
KICKSTART_TEMPLATE=centos-7-minimal.template

BUILD_DIR=$(shell pwd)/build
ISO_NAME=live-centos

HANDLE_USER_DATA=$(shell base64 -w 0 scripts/handle-user-data)
DOCKER_SOCKET=$(shell base64 -w 0 scripts/docker.socket)

default: iso

kickstart:
	mkdir -p $(BUILD_DIR)
	touch $(BUILD_DIR)/$(KICKSTART_FILE)
	cat $(KICKSTART_TEMPLATE) | handle_user_data='$(HANDLE_USER_DATA)' docker_socket='$(DOCKER_SOCKET)' envsubst  > $(BUILD_DIR)/$(KICKSTART_FILE)

iso: kickstart
	cd $(BUILD_DIR); sudo livecd-creator --config $(BUILD_DIR)/$(KICKSTART_FILE) --logfile=$(BUILD_DIR)/livecd-creator.log --fslabel $(ISO_NAME)

clean:
	rm -rf $(BUILD_DIR)

test:
	export NODE_ENV=test
	$(shell NODE_ENV=test "echo "$$PWD"" > ttt)

