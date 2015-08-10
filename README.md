## vm-bhyve

Management system for FreeBSD bhyve virtual machines

Some of the main features include:

* Simple commands to create/start/stop bhyve instances
* Simple configuration file format
* Virtual switches supporting vlans & nat (no manual tap or bridge devices needed)
* ZFS support
* FreeBSD/NetBSD/OpenBSD/Linux guest support
* Automatic assignment of console devices to access guest console
* Integration with rc.d startup/shutdown
* Guest reboot handling

## Install

Download the latest release from Github, or download from the following URL
[http://churchers.hostingspace.co.uk/vm-bhyve-latest.tgz](http://churchers.hostingspace.co.uk/vm-bhyve-latest.tgz)

To install, just run the following command inside the vm-bhyve source directory

    # make install

If you want to run guests other than FreeBSD, you will need the grub2-bhyve package;

    # pkg install grub2-bhyve

Additionally, NAT support is only available if you have dnsmasq installed.

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
can create as many templates as you like. For example for could have web-server.conf, containing the setting
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

This will automatically create a private network on the switch, enable DHCP for it, and forward guest traffic
via your default gateway. Please note that NAT functionality  requires the dnsmasq package to be installed, 
and both dnsmasq & pf must be enabled in /etc/rc.conf. See the man page for more details.

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
    deb             debian     1      512M      Yes [2]      Stopped

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
