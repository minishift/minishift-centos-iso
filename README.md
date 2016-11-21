<a name="creating-a-centos-live-iso"></a>
# Creating a CentOS Live ISO

<!-- MarkdownTOC -->

- [Building the ISO](#building-the-iso)
	- [On CentOS 7](#on-centos-7)
		- [Prerequisites](#prerequisites)
		- [Building the CentOS ISO](#building-the-iso-1)
		- [Building the RHEL ISO](#building-the-iso-2)
	- [On hosts without _livecd-tools_ \(OS X, Windows, ...\)](#on-hosts-without-livecd-tools-os-x-windows-)
		- [Prerequisites](#prerequisites-1)
		- [Building the ISO](#building-the-iso-2)
- [Further reading](#further-reading)

<!-- /MarkdownTOC -->

<a name="building-the-iso"></a>
## Building the ISO

<a name="on-centos-7"></a>
### On CentOS 7

<a name="prerequisites"></a>
#### Prerequisites

* [livecd-tools](https://github.com/rhinstaller/livecd-tools)

        $ yum install -y livecd-tools

<a name="building-the-iso-1"></a>
#### Building the CentOS ISO

```
$ git clone https://github.com/LalatenduMohanty/centos-live-iso.git
$ cd centos-live-iso
$ make
```

<a name="building-the-iso-2"></a>
#### Building the RHEL ISO

To build the RHEL iso make sure you export required variable before execute **make**

```
$ git clone https://github.com/LalatenduMohanty/centos-live-iso.git
$ cd centos-live-iso
$ export rhel_tree_url="<rhel_tree_to_fetch_kernel>"
$ export base_repo_url="<base_repo_url_to_install_packages>"
$ export updates_repo_url="<updates_repo_url_to_package_updates>"
$ make rhel_iso
```

<a name="on-hosts-without-livecd-tools-os-x-windows-"></a>
### On hosts without _livecd-tools_ (OS X, Windows, ...)

<a name="prerequisites-1"></a>
#### Prerequisites

* [Vagrant](https://www.vagrantup.com/)
* vagrant-sshfs

        $ vagrant plugin install vagrant-sshfs

<a name="building-the-iso-2"></a>
#### Building the ISO

```
$ git clone https://github.com/LalatenduMohanty/centos-live-iso.git
$ cd centos-live-iso
$ vagrant up
$ vagrant ssh
$ cd <path to centos-live-iso directory on the VM>/centos-live-iso
$ make
```

<a name="further-reading"></a>
## Further reading

Once you are able to build the ISO, you are most likely interested to modify the
image itself. To do so you have to get familiar with the [Kickstart documentation](https://github.com/rhinstaller/pykickstart/blob/master/docs/kickstart-docs.rst).
