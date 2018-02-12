<a name="creating-a-minishift-centos-iso"></a>
# Minishift CentOS ISO

This repository contains all the instructions and code to build a Live ISO based on CentOS
which can be used by [minishift](https://github.com/minishift/minishift) as an alternative to
the boot2docker ISO.

----

<!-- MarkdownTOC -->

- [Building the CentOS ISO](#building-the-centos-iso)
	- [On CentOS-7](#on-centos)
		- [Prerequisites](#prerequisites)
		- [Building the ISO](#building-the-iso)
	- [On hosts _other than CentOS-7_ \(OS X, Windows, Fedora ...\)](#non-centos7-hosts)
		- [Prerequisites](#prerequisites-1)
		- [Building the ISO](#building-the-iso-1)
- [Building the RHEL ISO](#building-the-rhel-iso)
- [Releasing Minishift ISO](#releasing-minishift-iso)
- [Tests](#tests)
- [CI Setup](#ci-setup)
- [Further reading](#further-reading)
- [Community](#community)

<!-- /MarkdownTOC -->

[![Build Status](https://ci.centos.org/buildStatus/icon?job=minishift-centos-iso)](https://ci.centos.org/job/minishift-centos-iso/)

----

<a name="building-the-centos-iso"></a>
## Building the CentOS ISO

The following contains instructions on how to build the default (CentOS7 based) ISO.
If you are able to install [livecd-tools](https://github.com/rhinstaller/livecd-tools)
directly on your machine, you can use the [CentOS](#on-centos) instructions.

If you don't have _livecd-tools or using different linux distro other than centos_, follow the
[hosts other than CentOS-7](#non-centos7-hosts) instructions.

<a name="on-centos"></a>
### On CentOS

<a name="prerequisites"></a>
#### Prerequisites
* Update your system before start and if there is kernel update then reboot your system to activate latest kernel.

        $ yum update -y

* [Install livecd-tools](https://github.com/rhinstaller/livecd-tools)

  Note: We use to have docker installed on system to get selinux context, [check bugzilla](https://bugzilla.redhat.com/show_bug.cgi?id=1303565)

        $ yum install -y livecd-tools docker


<a name="building-the-iso"></a>
#### Building the ISO

```
$ git clone https://github.com/minishift/minishift-centos-iso.git
$ cd minishift-centos-iso
$ make
```

<a name="non-centos7-hosts"></a>
### On hosts _other than CentOS-7_ (OS X, Windows, Fedora ...)

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

<a name="tests"></a>
## Tests

Tests are written as a shell script in `tests/test.sh`.

Note: Running the tests in Windows OS is unsupported.

#### Build ISO

Setup your build environment by following the instructions provided in [Building the CentOS ISO](#building-the-centos-iso) section as per your preferred OS.

Note: Building ISO might require you to have Vagrant environment if you are not using host other than CentOS.

#### Run the tests:

Once the ISO is built from above step, use following command to run tests:

```
$ make test
```

Note: If you are using the Vagrant environment, you need to exit from it and come back to host to run the above command.

This command will fetch the latest [Minishift](http://github/minishift/minishift) binary and run the [tests](tests/test.sh).

<a name="ci-setup"></a>
## CI Setup

`minishift-centos-iso` uses [CentOS CI](https://ci.centos.org/) as CI build server.
It builds incoming pull requests and any push to master along with archiving the build artifacts.
You can find the CentOS CI jenkins master job [here](https://ci.centos.org/job/minishift-centos-iso/) and the pull request job [here](https://ci.centos.org/job/minishift-centos-iso-pr/).

On a successful pull request build, the build artifacts can be found at
[artifacts.ci.centos.org/minishift/minishift-centos-iso/pr/\<PR ID\>](http://artifacts.ci.centos.org/minishift/minishift-centos-iso/pr/).

On a successful master build, the build artifacts can be found at
[artifacts.ci.centos.org/minishift/minishift-centos-iso/master/\<BUILD ID\>](http://artifacts.ci.centos.org/minishift/minishift-centos-iso/master/).

For more information about CentOS CI, check out its [Wiki](https://wiki.centos.org/QaWiki/CI) to
know more about CentOS CI.

<a name="further-reading"></a>
## Further reading

Once you are able to build the ISO, you are most likely interested to modify the
image itself. To do so you have to get familiar with
[pykickstart](https://github.com/rhinstaller/pykickstart/blob/master/docs/kickstart-docs.rst).

<a name="community"></a>
## Community

You can reach the Minishift community by:

- Signing up to our [mailing list](https://lists.minishift.io/admin/lists/minishift.lists.minishift.io)

- Joining the `#minishift` channel on [Freenode IRC](https://freenode.net/)
