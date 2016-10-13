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
curl
docker
dracut
efibootmgr
grub2
grub2-efi
kernel
net-tools
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

# TODO Why can I not generate the docker user outside of this init script as part
# of the kickstart file?
# https://github.com/LalatenduMohanty/centos-live-iso/issues/10
useradd -p tcuser docker
groupadd docker
usermod -a -G docker docker

# TODO Need to make sure to have /sbin on the PATH. Is there a better way?
# http://stackoverflow.com/questions/19983710/some-commands-not-wroking-on-remote-servers-through-ssh-shell
# https://github.com/LalatenduMohanty/centos-live-iso/issues/11
echo 'PATH=$PATH:/sbin' >> /home/docker/.bashrc

# If there is a partition with `boot2docker-data` as its label we are dealing with
# an already bootstrapped docker-machine.
BOOT2DOCKER_DATA=`blkid -o device -l -t LABEL=$LABEL`
if [ -n "$BOOT2DOCKER_DATA" ]; then
	exit 0
fi

# Test for our magic string (it means that the disk was made by ./boot2docker init)
HEADER=`dd if=/dev/sda bs=1 count=${#MAGIC} 2>/dev/null`

if [ "$HEADER" = "$MAGIC" ]; then
	# Read /userdata.tar with ssh keys
	# TODO we need to add checks whether the userdata.tar is still there or whether
	# the disk got already formatted
	dd if=/dev/sda of=/userdata.tar bs=1 count=4096 2>/dev/null
	tar xf /userdata.tar -C /home/docker/ > /var/log/userdata.log 2>&1
	chown -R docker:docker /home/docker/.ssh
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
