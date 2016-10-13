sshpw --username=root --plaintext centos
# Firewall configuration
firewall --disabled
selinux --disabled

# Use network installation
url --url="http://mirror.centos.org/centos/7/os/x86_64/"
network --bootproto=dhcp --device=link --activate --onboot=on
skipx
rootpw --plaintext centos
auth --useshadow --passalgo=sha512

timezone --utc America/New_York
bootloader --location=mbr --append="no_timer_check console=tty0 console=ttyS0,115200 net.ifnames=0 biosdevname=0"
clearpart --all
part / --fstype="ext4" --size=10240

#Repos
repo --name=base --baseurl=http://mirror.centos.org/centos/7/os/x86_64/
repo --name=updates --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/
repo --name=extras --baseurl=http://mirror.centos.org/centos/7/extras/x86_64/

user --name=docker --password=tcuser

shutdown

%packages  --excludedocs --instLangs=en
@core
bash
centos-logos
docker
dracut
e4fsprogs
efibootmgr
grub2
grub2-efi
kernel
net-tools
parted
shadow-utils
shim
syslinux

#Packages to be removed
-aic94xx-firmware
-alsa-firmware
-btrfs-progs
-e2fsprogs
-iprutils
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-iwl7265-firmware
-parted
-postfix
-rsyslog
%end

%post

# Setting a global Locale for the server
echo "LANG=\"C\"" > /etc/locale.conf

# sudo permission
echo "%docker ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/docker
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

cat > /etc/rc.d/init.d/handle-user-data << EOF
#!/bin/sh
LABEL=boot2docker-data
MAGIC="boot2docker, please format-me"
UNPARTITIONED_HD=/dev/sda

# Function to mount the data partition
mount_data_partition() {
    PARTNAME=\`echo "\$BOOT2DOCKER_DATA" | sed 's/.*\///'\`
    echo "mount p:\$PARTNAME ..."
    mkdir -p /mnt/\$PARTNAME
    if ! mount \$BOOT2DOCKER_DATA /mnt/\$PARTNAME 2>/dev/null; then
        # for some reason, mount doesn't like to modprobe btrfs
        BOOT2DOCKER_FSTYPE=\`blkid -o export \$BOOT2DOCKER_DATA | grep TYPE= | cut -d= -f2\`
        modprobe \$BOOT2DOCKER_FSTYPE || true
        umount -f /mnt/\$PARTNAME || true
        mount \$BOOT2DOCKER_DATA /mnt/\$PARTNAME
    fi

    # Just in case, the links will fail if not
    umount -f /var/lib/docker || true
    rm -rf /var/lib/docker /var/lib/boot2docker

    # Detected a disk with a normal linux install (/var/lib/docker + more))
    mkdir -p /var/lib

    mkdir -p /mnt/\$PARTNAME/var/lib/docker
    ln -s /mnt/\$PARTNAME/var/lib/docker /var/lib/docker

    mkdir -p /mnt/\$PARTNAME/var/lib/boot2docker
    ln -s /mnt/\$PARTNAME/var/lib/boot2docker /var/lib/boot2docker

    # Make sure /tmp is on the disk too
    rm -rf /mnt/\$PARTNAME/tmp || true
    mv /tmp /mnt/\$PARTNAME/tmp
    ln -fs /mnt/\$PARTNAME/tmp /tmp

    # Move userdata to persistent storage
    if [ -e "/userdata.tar" ]; then
        mv /userdata.tar /var/lib/boot2docker/
    fi

    ls -l /mnt/\$PARTNAME
}

# Function to partion and format the data disk
prepare_data_partion() {
    # Create the partition, format it and then mount it
    echo "NEW boot2docker managed disk image (\$UNPARTITIONED_HD): formatting it for use"

    # Add a swap partition (so Docker doesn't complain about it missing)
    (echo n; echo p; echo 2; echo ; echo +1000M ; echo w) | fdisk \$UNPARTITIONED_HD
    # Let kernel re-read partition table
    partprobe

    (echo t; echo 82; echo w) | fdisk \$UNPARTITIONED_HD
    # Let kernel re-read partition table
    partprobe
    # wait for the partition to actually exist, timeout after about 5 seconds
    local timer=0
    while [ "\$timer" -lt 10 -a ! -b "\${UNPARTITIONED_HD}2" ]; do
    	timer=\$((timer + 1))
        sleep 0.5
    done

    # Activate the swap partition
    mkswap "\${UNPARTITIONED_HD}2"

    # Add the data partition
    (echo n; echo p; echo 1; echo ; echo ; echo w) | fdisk \$UNPARTITIONED_HD
    # Let kernel re-read partition table
    partprobe
    # wait for the partition to actually exist, timeout after about 5 seconds
    timer=0
    while [ "\$timer" -lt 10 -a ! -b "\${UNPARTITIONED_HD}1" ]; do
    	timer=\$((timer + 1))
        sleep 0.5
    done

    BOOT2DOCKER_DATA=\`echo "\${UNPARTITIONED_HD}1"\`
    mkfs.ext4 -i 8192 -L \$LABEL \$BOOT2DOCKER_DATA
    swapon "\${UNPARTITIONED_HD}2"
}

# Function to extract userdata.tar containing the ssh keys into the home directory /home/docker
handle_user_data_tar() {
	# Extract the userdata into docker user home directory
	if [ -e "/var/lib/boot2docker/userdata.tar" ]; then
		tar xf /var/lib/boot2docker/userdata.tar -C /home/docker/ > /var/log/userdata.log 2>&1
    	rm -f '/home/docker/boot2docker, please format-me'
		chown -R docker:docker /home/docker/.ssh
	else
		echo "Unable to find userdata.tar"
		exit 1
	fi
}

# TODO Why can I not generate the docker user outside of this init script as part
# of the kickstart file?
# https://github.com/LalatenduMohanty/centos-live-iso/issues/10
useradd -p tcuser docker
groupadd docker
usermod -a -G docker docker

# TODO Need to make sure to have /sbin on the PATH. Is there a better way?
# http://stackoverflow.com/questions/19983710/some-commands-not-wroking-on-remote-servers-through-ssh-shell
# https://github.com/LalatenduMohanty/centos-live-iso/issues/11
echo 'PATH=\$PATH:/sbin' >> /home/docker/.bashrc

# If there is a partition with `boot2docker-data` as its label we are dealing with
# an already bootstrapped docker-machine. Just make sure to mount data partition and to unpack
# userdata.tar. Remember, /home/docker is not persistent
BOOT2DOCKER_DATA=\`blkid -o device -l -t LABEL=\$LABEL\`
if [ -n "\$BOOT2DOCKER_DATA" ]; then
	mount_data_partition
	handle_user_data_tar
	exit 0
fi

# Test for our magic string (it means that the disk was made by ./boot2docker init)
HEADER=\`dd if=\$UNPARTITIONED_HD bs=1 count=\${#MAGIC} 2>/dev/null\`
if [ "\$HEADER" = "\$MAGIC" ]; then
	# Read /userdata.tar with ssh keys and place it temporarily under /
	dd if=/dev/sda of=/userdata.tar bs=1 count=4096 2>/dev/null

    prepare_data_partion
    mount_data_partition
	handle_user_data_tar
fi
EOF

chmod +x /etc/rc.d/init.d/handle-user-data
/sbin/restorecon /etc/rc.d/init.d/handle-user-data

chmod +x /etc/rc.d/rc.local
echo "/etc/rc.d/init.d/handle-user-data" >> /etc/rc.d/rc.local

# Remove redhat-logo and firmware package to help with reduce box size
yum remove -y redhat-logos linux-firmware

# Clear yum package and metadata cache
yum clean all

rm -rf /usr/lib/locale/locale-archive
rm -rf /var/cache/yum/*

%end
