# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |v, override|
    v.memory = 2048
    v.cpus   = 2
    v.customize ["modifyvm", :id, "--cpus", "2"]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.provider "libvirt" do |v, override|
    v.driver = "kvm"
    v.memory = 2048
    v.cpus   = 2
    v.suspend_mode = "managedsave"
  end

  config.vm.synced_folder '.', '/vagrant', disabled: true
  if Vagrant::Util::Platform.windows?
    target_path = ENV['USERPROFILE'].gsub(/\\/,'/').gsub(/[[:alpha:]]{1}:/){|s|'/' + s.downcase.sub(':', '')}
    config.vm.synced_folder ENV['USERPROFILE'], target_path, type: 'sshfs', sshfs_opts_append: '-o umask=000 -o uid=1000 -o gid=1000'
  else
    config.vm.synced_folder ENV['HOME'], ENV['HOME'], type: 'sshfs', sshfs_opts_append: '-o umask=000 -o uid=1000 -o gid=1000'
  end

  config.vm.provision "shell", inline: <<-SHELL
    # Docker and parted is required to get selinux context: https://bugzilla.redhat.com/show_bug.cgi?id=1303565
    sudo yum install -y git livecd-tools docker parted
  SHELL
end
