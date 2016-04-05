## vm-bhyve

Management system for FreeBSD bhyve virtual machines

Some of the main features include:

* Now with beta Windows/UEFI support as of v0.7.2!
* Simple commands to create/start/stop bhyve instances
* Simple configuration file format
* Virtual switches supporting vlans & nat (no manual tap or bridge devices needed)
* ZFS support
* FreeBSD/NetBSD/OpenBSD/Linux guest support
* Automatic assignment of console devices to access guest console
* Integration with rc.d startup/shutdown
* Guest reboot handling
* Designed with multiple compute nodes + shared storage in mind (NFS/iSCSI/etc)

## IMPORTANT - Note for Linux/NetBSD & OpenBSD users moving from 0.9 to 0.10

The method of supporting these guests has been heavily changed in 0.10 to
allow more flexibility. These guests will no longer boot without making changes
to the configuration file. (Note the `vm configure guest` command can be used to open
the guest configuration in your default editor)

First of all, if you are using Linux, the guest configuration option needs to be changed to `linux`.
For NetBSD & OpenBSD, the following configuration options should be set.

    guest="generic"
    loader="grub"

Additionally, any grub commands needed to boot the guest (or the guest installer) need to also
be added to the configuration file. Please look at the sample templates in 0.10 for examples
on how these variables are set. This is what the configuration for OpenBSD 5.9 looks like:

    grub_install0="kopenbsd -h com0 /5.9/amd64/bsd.rd"
    grub_install1="boot"
    grub_run_partition="openbsd1"
    grub_run0="kopenbsd -h com0 -r sd0a /bsd"
    grub_run1="boot"

The partition option is not required, the following is also functional:

    grub_run0="kopenbsd -h com0 -r sd0a (hd0,openbsd1)/bsd"
    grub_run1="boot"

(However some guests such as Ubuntu will boot automatically, without any boot commands specified,
if the correct partition is provided)

This of course means that it is now trivial to adjust these commands if needed, whereas in
previous versions of vm-bhyve, they were hard-coded.

If boot commands are specified, `grub-bhyve` is run in the background and commands are piped
in automatically by `vm-bhyve`. If no commands are specified, `grub-bhyve` is run on the guests
console, and so the bootloader can be accessed using `vm console guest` if required.

## Install

Download the latest release from Github, or install `sysutils/vm-bhyve`

To install, just run the following command inside the vm-bhyve source directory

    # make install

If you want to run guests other than FreeBSD, you will need the grub2-bhyve package;

    # pkg install grub2-bhyve

Additionally, while not specifically required, dnsmasq can be used to provid DHCP services
when vm-bhyve is configured to run NAT.

    # pkg install dnsmasq

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

If you want to use NAT, do not add a physical interface to the switch, as the switch will be on the private
side of the NAT network. Just enable NAT on the switch:

    # vm switch nat public on

This will automatically create a private network on the switch, and forward guest traffic
via your default gateway. Please note that pf must be enabled in /etc/rc.conf for NAT functionality to work.
Whilst not strictly required, dnsmasq can be used to provide DHCP services to guests on the NAT network.
vm-bhyve will generate a sample dnsmasq.conf file which can be installed for this purpose.

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

    # vm iso ftp://ftp.freebsd.org/pub/FreeBSD/releases/ISO-IMAGES/10.1/FreeBSD-10.1-RELEASE-amd64-disc1.iso

To start a guest install, run the following command. vm-bhyve will run the machine in the background,
so use the console command to connect to it and finish installation.

    # vm install testvm FreeBSD-10.1-RELEASE-amd64-disc1.iso
    # vm console testvm

Once installation has finished, you can reboot the guest from inside the console and it will boot up into
the new OS (assuming installation was successful). Further reboots will work as expected and
the guest can be shutdown in the normal way. As the console uses the cu command, type ~+Ctrl-D to exit
back to your host.

The following commands start and stop virtual machines:

    # vm start testvm
    # vm stop testvm

The basic configuration of each machine and state can be viewed using the list command:

    # vm list
    NAME            GUEST      CPU    MEMORY    AUTOSTART    STATE
    alpine          alpine     1      512M      Yes [1]      Stopped
    centos          centos     1      512M      No           Stopped
    deb             debian     1      512M      Yes [2]      Running (23903)

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

There's also a command which opens a guest's confiuration file in your default text editor, allowing
you to easily make changes to the configuration. Please note that changes only take effect after
a full shutdown and restart of the guest

    # vm configure testvm

See the man page for a full description of all available commands.

    # man vm
    
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

Windows has been very quickly tested as of version 0.7.2 (Using Server 2012R2).
I see no reason why other versions supported by bhyve shouldn't work as the basic bhyve
commands are all the same. Please note that you need FreeBSD 10.3 or 11-CURRENT for the UEFI support
to be functional.

As there is no VGA console, you must follow the instructions at 
https://people.freebsd.org/~grehan/bhyve_uefi/windows_iso_repack.txt 
to create an unattended installation ISO. This requires a few packages to be installed but
is fairly straight forward if you follow the instructions carefully.

You also need the UEFI firmware, which can be retrieved from
http://people.freebsd.org/~grehan/bhyve_uefi/BHYVE_UEFI_20151002.fd
and needs to be placed in `$vm_dir/.config/BHYVE_UEFI.fd`.

Once you have an ISO capable of installing without user interaction, vm-bhyve works as normal.
Just copy the ISO to `$vm_dir/.iso/`, then run the following to install:

    # vm create -t windows -s 50G winguest
    # vm install winguest mywiniso.iso

Installation can take around 25 minutes. If you look in the vm-bhyve.log file in the virtual
machines directory, you should see it reboot twice. After the second reboot (third run in total)
the machine should boot into Windows. Access the Windows console using the `vm console winguest` command,
then press `i` to get its IP address (It will use DHCP). You can then RDP to the guest.
The default login details are Administrator and Test123.

## Autocomplete

If you are using the default csh/tcsh shell built into FreeBSD, running the following command should allow
autocomplete to work for all the currently supported functions. This is especially useful for viewing
and completing guest & ISO file names. Please note that there's three ocurrances of '/path/to/vm' which
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
