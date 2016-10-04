sshpw --username=root --plaintext centos
# Firewall configuration
firewall --disabled
selinux --disabled
#Use network installation
url --url="http://mirror.centos.org/centos/7/os/x86_64/"
network --bootproto=dhcp --device=link --activate --onboot=on
skipx
rootpw --plaintext centos
auth --useshadow --passalgo=sha512
timezone --utc America/New_York
bootloader --location=mbr --append="no_timer_check console=tty0 console=ttyS0,115200 net.ifnames=0 biosdevname=0"
clearpart --all
part / --size=8192 --fstype ext4

#Repos
repo --name=base --baseurl=http://mirror.centos.org/centos/7/os/x86_64/
repo --name=updates --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/
repo --name=extras --baseurl=http://mirror.centos.org/centos/7/extras/x86_64/

shutdown

%packages  --excludedocs --instLangs=en
@core
kernel
dracut
docker
# For UEFI/Secureboot support
grub2
grub2-efi
efibootmgr
shim

#Packages to be removed
-btrfs-progs
-parted
-rsyslog
-iprutils
-e2fsprogs
-aic94xx-firmware
-alsa-firmware
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
-postfix
%end

%post

LANG="en_US"
echo "%_install_lang $LANG" > /etc/rpm/macros.image-language-conf

systemctl enable docker

# Remove redhat-logo and firmware package to help with reduce box size
yum remove -y redhat-logos linux-firmware
# Remove doc except copyright
find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true
# Clear yum package and metadata cache
yum clean all

rm -fr /usr/lib/locale/locale-archive
rm -rf /var/cache/yum/*
%end
