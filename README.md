# vm-bhyve

FreeBSD Bhyve VM Management

Bhyve manager with the following functionality

* Simple virtual switch management - no messing with manual tap devices or bridges
* Automatic ZFS dataset creation
* Startup and shutdown integration
* Automatic handling of reboot and shutdown events
* Dynamic console (nmdm device) creation
* FreeBSD/NetBSD/OpenBSD/Linux guest support
* Simple NAT support based on dnsmasq & pf

##Download

Download a bundle containing the latest version from [http://churchers.hostingspace.co.uk/vm-bhyve-latest.tgz](http://churchers.hostingspace.co.uk/vm-bhyve-latest.tgz)

Please note the manual page contains the most up to date information on supported commands and usage.
Once installed, use 'man vm' to view.

##Initial setup instructions

Install the vm script using the Makefile

    # make install

Create a directory for the virtual machines
(See the note below about usage on ZFS)

    # make vmdir PATH=/path/to/my/vms
    
Update `/etc/rc.conf`

    vm_enable="YES"
    vm_dir="/path/to/my/vms"
    vm_list="" # list to start automatically on boot
    vm_delay="5" # seconds delay between starting machines
    
ZFS NOTE: If you want to store guests on a ZFS dataset, and have a new child dataset created for each virtual machine,
specify the dataset to use as below in place of the vm directory. You will need to create the dataset manually first,
then use the "make vmdir" command above to set up the subdirectories and copy sample templates:

    in /etc/rc.conf -> vm_dir="zfs:pool/dataset"

    # make vmdir PATH=/path/to/pool/dataset/mountpoint

Initialise all kernel modules and get the system ready to run bhyve.
This command needs to be run once after each host reboot (this is normally handled by the rc.d script included):

    # vm init
    
This completes the basic setup

##Virtual Switch Management

Create a new virtual switch called 'public' and assign em0 to it:
You can use any name you like (lan/internet/etc), although the included templates are set to create one interface on a switch called 'public'. (Obviously you can change the templates if you like)

    # vm switch create public
    # vm switch add public em0
    
We can also set a vlan number so all traffic heading out of em0 will be tagged:

    # vm switch vlan public 10
    
List the configured switches and their associated bridge device

    # vm switch list

##NAT

To enable nat on a virtual switch, run the following command

    # vm switch nat switch-name on

The switch should have no ports assigned, and will automatically use your default
gateway to forward packets from the guest network.

This requires the dnsmasq paackage to be installed. Both dnsmasq & pf should be enabled
in /etc/rc.conf. Note that vm-bhyve will overwrite any existing dnsmasq configuration when
nat is enabled. If you have an existing pf ruleset in /etc/pf.conf, this will be kept and a
single include statement will be added to load the vm-bhyve nat rules.

When enabled on a switch, a 172.16.x.0/24 network is assigned to the switch automatically, which
may cause problems if you have other interfaces on the host using the same range. The x number
is chosen based on the bridge interface number of the virtual switch; A virtual switch which
is using bridge1 on the host, will use 172.16.1.0/24 for nat.

##Virtual Machines

Create a new 20G virtual machine using the `default.conf` standard template, and a second 40G ubuntu machine using the `ubuntu.conf` template:

    # vm create -s 20G vm1
    # vm create -t ubuntu -s 40G vm2
    
Download an ISO file for installation:

    # vm iso ftp://ftp.freebsd.org/pub/FreeBSD/releases/ISO-IMAGES/10.1/FreeBSD-10.1-RELEASE-amd64-disc1.iso

Start the install:

This will run the bootloader and start bhyve in the background. Connect to the console to complete the install
Once complete, if you reboot the machine at the end of the install process, the machine will reboot as expected and boot up normally. Reboots will work as expected and the machine can be shutdown from the guest in the normal way.

    # vm install vm1 FreeBSD-10.1-RELEASE-amd64-disc1.iso
    # vm console vm1
    
To stop a single virtual machine, or all virtual machines from the host:

    # vm stop vm1
    # vm stopall
    
Start all virtual machines listed in /etc/rc.conf from the host:

To account for the possibility of shared storage being used which contains other machines we don't want running on this host, the list of machines to start is set via the `vm_list=""` variable in `/etc/rc.conf`

    # vm startall

All network interfaces and nmdm console devices are created dynamically as the guest is started. The entire time the guest is running, vm sits in the background waiting to handle the bhyve shutdown/reboot. Once a guest is shutdown or exits for any other non-reboot reason, all interfaces and nmdm devices are cleaned up.

As an additional example, a private switch to allow two guests to communicate can be created as follows:

    # vm switch create private
    
Then add the following to the `/path/to/my/vms/vmname/vmname.conf` file for each guest and then shutdown/restart the guests.

    network1_type="virtio-net"
    network1_switch="private"
