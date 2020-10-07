## vm-bhyve

Management system for FreeBSD bhyve virtual machines

Some of the main features include:

* Windows/UEFI support
* Simple commands to create/start/stop bhyve instances
* Simple configuration file format
* Virtual switches supporting vlans & automatic device creation
* ZFS support
* FreeBSD/NetBSD/OpenBSD/Linux guest support
* Automatic assignment of console devices to access guest console
* Integration with rc.d startup/shutdown
* Guest reboot handling
* Designed with multiple compute nodes + shared storage in mind (NFS/iSCSI/etc)
* Multiple datastores
* VNC graphics & tmux support (1.1+ only. See wiki for instructions)
* Dependency free**

** Some additional packages may be required in certain circumstances -

* The port has a dependancy on ca_root_nss added by the ports maintainers to help avoid any SSL errors when downloading FreeBSD ISO files using the `vm iso` command.
* `sysutils/grub2-bhyve` is required to run Linux or any other guests that need a Grub bootloader.
* `sysutils/bhyve-firmware` is required to run UEFI guests
* `sysutils/tmux` is needed to use tmux console access instead of cu/nmdm


##### See the GitHub wiki for more information and examples.

For most users, I recommend using the version in ports (1.1+).
Main development happens in the master branch on GitHub and it may contain broken or incomplete features.

## Quick-Start

A simple overview of the commands needed to install vm-bhyve and start a freebsd guest.
See the sections below for more in-depth details.

    1. pkg install vm-bhyve
    2. zfs create pool/vm
    3. sysrc vm_enable="YES"
    4. sysrc vm_dir="zfs:pool/vm"
    5. vm init
    6. cp /usr/local/share/examples/vm-bhyve/* /mountpoint/for/pool/vm/.templates/
    7. vm switch create public
    8. vm switch add public em0
    9. vm iso https://download.freebsd.org/ftp/releases/ISO-IMAGES/11.2/FreeBSD-11.2-RELEASE-amd64-bootonly.iso
    10. vm create myguest
    11. vm install [-f] myguest FreeBSD-11.2-RELEASE-amd64-bootonly.iso
    12. vm console myguest

- [ ] Line 1
Install vm-bhvye

- [ ] Line 2
Create a dataset for your virtual machines.
If you're not using ZFS, just create a normal directory.

- [ ] Lines 3-4
Enable vm-bhyve in /etc/rc.conf and set the dataset to use.
If not using ZFS, just set `$vm_dir="/my/vm/folder"`.

- [ ] Line 5
Run the `vm init` command to create the required directories under $vm_dir and load kernel modules.

- [ ] Line 6
Install the sample templates that come with vm-bhyve.

- [ ] Lines 7-8
Create a virtual switch called 'public' and attach your network interface to it.
Replace `em0` with whatever interface connects your machine to the network.

- [ ] Line 9
Download a copy of FreeBSD from the ftp site.

- [ ] Lines 10-12
Create a new guest using the `default.conf` template, run the installer and
then connect to its console. At this point proceed through the installation 
as normal. By specifying the `-f` option before the install command, the guest
will run directly on your terminal so the `console` command is not required. (Bear
in mind that you won't get back to your terminal until the guest is fully shutdown)

## Install

Download the latest release from GitHub, or install `sysutils/vm-bhyve`

To install, just run the following command inside the vm-bhyve source directory

    # make install

If you want to run guests other than FreeBSD, you will need the grub2-bhyve package;

    # pkg install grub2-bhyve

## Initial configuration

First of all, you will need a directory to store all your virtual machines and vm-bhyve configuration.
If you are not using ZFS, just create a normal directory:

    # mkdir /somefolder/vm

If you are using ZFS, create a dataset to hold vm-bhyve data

    # zfs create pool/vm

Now update /etc/rc.conf to enable vm-bhyve, and tell it where your directory is

    vm_enable="YES"
    vm_dir="/somefolder/vm"

Or with ZFS:

    vm_enable="YES"
    vm_dir="zfs:pool/vm"

This directory will be referred to as $vm_dir in the rest of this readme.

Now run the following command to create the directories used to store vm-bhvye configuration and
load any necessary kernel modules. This needs to be run once after each host reboot, which is
normally handled by the rc.d script

    # vm init

## Virtual machine templates

When creating a virtual machine, you use a template which defines how much memory to give the guest,
how many cpu cores, and networking/disk configuration. The templates are all stored inside $vm_dir/.templates.
To install the sample templates, run the following command:

    # cp /usr/local/share/examples/vm-bhyve/* /my/vm/path/.templates/

If you look inside the template files with a text editor, you will see they are very simple. You
can create as many templates as you like. For example you could have web-server.conf, containing the setting
for your web servers, or freebsd-large.conf for large FreeBSD guests, and so on. This is the contents of
the default template:

    guest="freebsd"
    loader="bhyveload"
    cpu=1
    memory=256M
    disk0_type="virtio-blk"
    disk0_name="disk0.img"
    network0_type="virtio-net"
    network0_switch="public"

You will notice that each template is set to create one network interface. You can easily add more network
interfaces by duplicating the two network configuration options and incrementing the number. In general you
will not want to change the type from 'virtio-net', but you will notice the first interface is set to connect 
to a switch called 'public'. See the next section for details on how to configure virtual switches.

I recommend reading the man page or `sample-templates/config.sample` for a full list of supported template
options and a description of their purpose. Almost all bhyve functionality is supported and a large variety
of network/storage configurations can be achieved.

## Virtual Switches

When a guest is started, each network interface is automatically connected to the virtual switch specified
in the configuration file. By default all the sample templates connect to a switch called 'public', although
you can use any name. The following section shows how to create a switch called 'public', and configure various
settings:

    # vm switch create public

If you just want to bridge guests to your physical network, add the appropriate real interface to the switch.
Obviously you will need to replace em0 here with the correct interface name on your system:

    # vm switch add public em0

If you want guest traffic to be on a specific VLAN when leaving the host, specify a vlan number. To turn
off vlans, just set the vlan number to 0:

    # vm switch vlan public 10
    # vm switch vlan public 0

You can view current switch configuration using the list command:

    # vm switch list

## Creating virtual machines

Use one of the following command to create a new virtual machine:

    # vm create testvm
    # vm create -t templatename -s 50G testvm

The first example uses the default.conf template, and will create a 20GB disk image. The second
example specifies the templatename.conf template, and tells vm-bhyve to create a 50GB disk.

You will need an ISO to install the guest with, so download one using the iso command:

    # vm iso https://download.freebsd.org/ftp/releases/ISO-IMAGES/11.2/FreeBSD-11.2-RELEASE-amd64-disc1.iso

To start a guest install, run the following command. vm-bhyve will run the machine in the background,
so use the console command to connect to it and finish installation.

    # vm install testvm FreeBSD-11.2-RELEASE-amd64-disc1.iso
    # vm console testvm

You can also specify the foreground option to run the guest directly on your terminal:

    # vm -f install testvm FreeBSD-11.2-RELEASE-amd64-disc1.iso

Once installation has finished, you can reboot the guest from inside the console and it will boot up into
the new OS (assuming installation was successful). Further reboots will work as expected and
the guest can be shutdown in the normal way. As the console uses the cu command, type ~+Ctrl-D to exit
back to your host.

The following commands start and stop virtual machines:

    # vm start testvm
    # vm stop testvm

The basic configuration of each machine and state can be viewed using the list command:

    # vm list
    NAME            GUEST      LOADER      CPU    MEMORY    AUTOSTART    STATE
    alpine          linux      default     1      512M      No           Stopped
    c7              linux      default     1      512M      Yes [2]      Stopped
    centos          linux      default     1      512M      No           Stopped
    debian          linux      default     1      512M      No           Stopped
    fbsd            freebsd    default     1      256M      No           Stopped
    netbsd          generic    grub        1      256M      No           Stopped
    openbsd         generic    grub        1      256M      No           Stopped
    pf              freebsd    default     1      256M      Yes [1]      Stopped
    ubuntu          linux      default     1      512M      No           Stopped
    wintest         windows    default     2      2G        No           Running (2796)

All running machines can be stopped using the stopall command

    # vm stopall

On host boot, vm-bhyve will use the 'vm startall' command to start all machines. You can
control which guests start automatically using the following variables in /etc/rc.conf:

    vm_list="vm1 vm2"
    vm_delay="5"

The first defines the list of machines to start on boot, and the order to start them. The second
is the number of seconds to wait between starting each one. 5 seconds is the recommended setting,
although a longer delay is useful if you have disk intensive guests and don't want them all booting
at the same time.

There's also a command which opens a guest's configuration file in your default text editor, allowing
you to easily make changes to the configuration. Please note that changes only take effect after
a full shutdown and restart of the guest

    # vm configure testvm

See the man page for a full description of all available commands.

    # man vm

## Using cloud images

You can use cloud images to create virtual machines. The `vm img` command will download the image to datastore and 
uncompress it if needed (.xz, .tar.gz, and .gz files are supported). The image should be in RAW or QCOW2 format.
To use this feature you'll need install qemu-utils package:

    # pkg install qemu-utils

To launch FreeBSD using official cloud image:

    # vm img https://download.freebsd.org/ftp/releases/VM-IMAGES/11.2-RELEASE/amd64/Latest/FreeBSD-11.2-RELEASE-amd64.raw.xz
    # vm create -t freebsd-zvol -i FreeBSD-11.2-RELEASE-amd64.raw freebsd-cloud
    # vm start freebsd-cloud

To list downloaded images:

    # vm img
    DATASTORE           FILENAME
    default             CentOS-7-x86_64-GenericCloud-20180930_02.raw
    default             debian-9-openstack-amd64.qcow2
    default             Fedora-AtomicHost-28-1.1.x86_64.raw
    default             FreeBSD-11.2-RELEASE-amd64.raw
    default             xenial-server-cloudimg-amd64-uefi1.img

## Using cloud init

vm-bhyve has basic support for providing cloud-init configuration to the guest. You can enable it with `-C` option
to `vm create` command. You can also pass public SSH key to be injected into the guest with option `-k <file>`. 

Example:

    # vm create -t linux -i xenial-server-cloudimg-amd64-uefi1.img -C -k ~/.ssh/id_rsa.pub cloud-init-ubuntu
    # vm start cloud-init-ubuntu
    Starting cloud-init-ubuntu
    * found guest in /zroot/vm/cloud-init-ubuntu
    * booting...
    # ssh ubuntu@192.168.0.91
    The authenticity of host '192.168.0.91 (192.168.0.91)' can't be established.
    ECDSA key fingerprint is SHA256:6s9uReyhsIXRv0dVRcBCKMHtY0kDYRV7zbM7ot6u604.
    No matching host key fingerprint found in DNS.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added '192.168.0.91' (ECDSA) to the list of known hosts.
    Welcome to Ubuntu 16.04.5 LTS (GNU/Linux 4.4.0-141-generic x86_64)
    
## Adding custom disks

Scenario: If you have a vm on one zpool and would like to add a new virtual disk to it that resides on a different zpool.

Manually create a sparse-zvol (in this case 50G in size).

    # zfs create -sV 50G -o volmode=dev "zpool2/vm/yourvm/disk1"

Add it to your vm config file.
Please note, for Windows guests the type will need to be `ahci-hd`, as it does not have virtio-blk drivers.

    # vm configure yourvm

    disk1_name="/dev/zvol/zpool2/vm/yourvm/disk1"
    disk1_type="virtio-blk"
    disk1_dev="custom"

Restart your vm.

## Windows Support

Please see the Windows section in the [Wiki](https://github.com/churchers/vm-bhyve/wiki/Running-Windows)

## Autocomplete

If you are using the default csh/tcsh shell built into FreeBSD, running the following command should allow
autocomplete to work for all the currently supported functions. This is especially useful for viewing
and completing guest & ISO file names. Please note that there's three occurrences of '/path/to/vm' which
need to be changed to the directory containing your virtual machines.

To make the autocomplete features available permanently, add the following to your `$HOME/.cshrc` file. Then either
logout/login, or run `source ~/.cshrc` to cause the `.cshrc` file to be reloaded.

    complete vm \
     'p@1@(list create install start stop console configure reset poweroff destroy clone snapshot rollback add switch iso)@' \
     'n@create@n@' \
     'n@list@n@' \
     'n@iso@n@' \
     'n@switch@(list create add remove destroy vlan nat)@' \
     'N@switch@`sysrc -inqf /path/to/vm/.config/switch switch_list`@' \
     'N@install@`ls -1 /path/to/vm/.iso`@' \
     'N@nat@(off on)@' \
     'p@2@`ls -1 /path/to/vm | grep -v "^\." | grep -v "^images"`@'
