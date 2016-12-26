<a name="creating-a-minishift-centos-iso"></a>
# Minishift CentOS VM

This repository contains all the instructions and code to build a Live ISO based on CentOS
which can be used by [minishift](https://github.com/minishift/minishift) as an alternative to
the boot2docker ISO.

<!-- MarkdownTOC -->

- [Building the CentOS ISO](#building-the-centos-iso)
	- [On CentOS/Fedora](#on-centosfedora)
		- [Prerequisites](#prerequisites)
		- [Building the ISO](#building-the-iso)
	- [On hosts without _livecd-tools_ \(OS X, Windows, ...\)](#on-hosts-without-livecd-tools-os-x-windows-)
		- [Prerequisites](#prerequisites-1)
		- [Building the ISO](#building-the-iso-1)
- [Building the RHEL ISO](#building-the-rhel-iso)
- [Releasing Minishift ISO](#releasing-minishift-iso)
- [Further reading](#further-reading)
<!-- /MarkdownTOC -->

<a name="building-the-centos-iso"></a>
## Building the CentOS ISO

The following contains instructions on how to build the default (CentOS based) ISO.
If you are able to install [livecd-tools](https://github.com/rhinstaller/livecd-tools)
directly on your machine, you can use the [CentOS/Fedora](#on-centosfedora) instructions.

If you don't have _livecd-tools_, follow the
[hosts without livecd-tools](#on-hosts-without-livecd-tools-os-x-windows-) instructions.

<a name="on-centosfedora"></a>
### On CentOS/Fedora

<a name="prerequisites"></a>
#### Prerequisites

* [livecd-tools](https://github.com/rhinstaller/livecd-tools)

        $ yum install -y livecd-tools


<a name="building-the-iso"></a>
#### Building the ISO

```
$ git clone https://github.com/minishift/minishift-centos-iso.git
$ cd minishift-centos-iso
$ make
```

<a name="on-hosts-without-livecd-tools-os-x-windows-"></a>
### On hosts without _livecd-tools_ (OS X, Windows, ...)

<a name="prerequisites-1"></a>
#### Prerequisites

* [Vagrant](https://www.vagrantup.com/)
* [vagrant-sshfs](https://github.com/dustymabe/vagrant-sshfs)

        $ vagrant plugin install vagrant-sshfs

<a name="building-the-iso-1"></a>
#### Building the ISO

```
$ git clone https://github.com/minishift/minishift-centos-iso.git
$ cd minishift-centos-iso
$ vagrant up
$ vagrant ssh
$ cd <path to minishift-centos-iso directory on the VM>/minishift-centos-iso
$ make
```

<a name="building-the-rhel-iso"></a>
## Building the RHEL ISO

The [Makefile](Makefile) also allows you to build a equivalent ISO based on RHEL instead
of CentOS. However, it requires you to have Red Hat VPN access and you need to export
several environment variables prior to building:

```
$ git clone https://github.com/minishift/minishift-centos-iso.git
$ cd minishift-centos-iso
$ export rhel_tree_url="<rhel_tree_to_fetch_kernel>"
$ export base_repo_url="<base_repo_url_to_install_packages>"
$ export updates_repo_url="<updates_repo_url_to_package_updates>"
$ export cdk_repo_url="<repo_url_to_cdk-entitlement_package>"
$ make rhel_iso
```

<a name="releasing-minishift-iso"></a>
## Releasing Minishift ISO

- Assemble all the meaningful changes since the last release to create release notes.
- Bump the `VERSION` variable in the Makefile.
- Before you execute below command be sure to have a [Github personal access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use) defined in your environment as `GITHUB_ACCESS_TOKEN`.

Run:

```shell
make release
```

<a name="further-reading"></a>
## Further reading

Once you are able to build the ISO, you are most likely interested to modify the
image itself. To do so you have to get familiar with
[pykickstart](https://github.com/rhinstaller/pykickstart/blob/master/docs/kickstart-docs.rst).
