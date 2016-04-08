## Guest Templates

This file lists guests that have been tested and shows the configuration options
used to allow the installer and guest to boot. The goal is to build up a list
of configurations that people can use in their own templates. In the majority
of cases, guests have been tested using their default install options.

If you have successfully used a guest operating system not already listed here, 
please let me know so the list can be updated.

Please note I have left the network & disk settings out of these examples as
the format is identical for all guests. See the bottom of this page for
examples of various disk & network configurations.

All guests require cpu and memory options, which are very simple - 

    cpu=1
    memory=512M

If you are running `vm-bhyve-0.11` or newer, the grub guests no longer
need the `boot` command, so that option can be removed from the guest 
configuration file for both install & run.

For a full list of the available configuration options, along with a description
of each, please see the man page or `config.sample` in the sample-templates directory.

### FreeBSD / pfSense

This configuration file should support all verions of FreeBSD.
For pfSense I used the embedded kernel option which seems to work perfectly.

    guest="freebsd"
    loader="bhyveload"

### Windows

I would recommand using at least 1G memory for Windows, and the disk
emulation needs to be ahci-hd.

    guest="windows"
    uefi="yes"
    disk0_type="ahci-hd"

### NetBSD

    guest="generic"
    loader="grub"
    grub_install0="knetbsd -h -r cd0a /netbsd"
    grub_install1="boot"
    grub_run0="knetbsd -h -r ld0a (hd0,msdos1)/netbsd"
    grub_run1="boot"

### OpenBSD 5.9 amd64

Please note that the OpenBSD installer has the version number and CPU
architecture specified. i386 is reported to work, and other versions 
should work fine as long as the install grub command is updated as required.

    guest="generic"
    loader="grub"
    grub_install0="kopenbsd -h com0 /5.9/amd64/bsd.rd"
    grub_run1="boot"
    grub_run_partition="openbsd1"
    grub_run0="kopenbsd -h com0 -r sd0a /bsd"
    grub_run1="boot"

### Alpine Linux

    guest="linux"
    loader="grub"
    grub_install0="linux /boot/grsec initrd=/boot/initramfs-grsec alpine_dev=cdrom:iso9660 modules=loop,squashfs,sd-mod,usb-storage,sr-mod"
    grub_install1="initrd /boot/initramfs-grsec"
    grub_install2="boot"
    grub_run_partition="msdos1"
    grub_run0="linux /boot/vmlinuz-grsec root=/dev/vda3 modules=ext4"
    grub_run1="initrd /boot/initramfs-grsec"
    grub_run2="boot"

### CentOS 6 (LVM)

    guest="linux"
    loader="grub"
    grub_install0="linux /isolinux/vmlinuz"
    grub_install1="initrd /isolinux/initrd.img"
    grub_install2="boot"
    grub_run_partition="msdos1"
    grub_run0="linux /vmlinuz-2.6.32-573.el6.x86_64 root=/dev/mapper/VolGroup-lv_root"
    grub_run1="initrd /initramfs-2.6.32-573.el6.x86_64.img"
    grub_run2="boot"

### CentOS 7

    guest="linux"
    loader="grub"
    grub_install0="linux /isolinux/vmlinuz"
    grub_install1="initrd /isolinux/initrd.img"
    grub_install2="boot"
    grub_run_partition="msdos1"
    grub_run_dir="/grub2"

### Debian & Ubuntu

    guest="linux"
    loader="grub"
    grub_run_partition="msdos1"

## Disk Configuration

All guests need at least one disk image.
Below are some examples of possible disk configurations.
These examples all use `virtio-blk` as the emulation type, but most guests
also support `ahci-hd`. For Windows guests the type should always be `ahci-hd`.

Note that additional disks can be added to any guest by adding additional disk
options to the configuration file, but changing `0` to `1` and so on.

### Simple Sparse File

    disk0_type="virtio-blk"
    disk0_name="disk0.img"

### Sparse ZVOL

Non sparse zvols are also supported by just specifying `disk0_dev="zvol"`

    disk0_type="virtio-blk"
    disk0_name="disk0"
    disk0_dev="sparse-zvol"

### Custom Disk

This allows you to specify a custom path to a disk image. The disk could be a sparse
file, a ZVOL, or even a real disk under `/dev/`

    disk0_type="virtio-blk"
    disk0_name="/dev/ada10"
    disk0_dev="custom"

### Simple Sparse File With Options

    disk0_type="virtio-blk"
    disk0_name="disk0.img"
    disk0_opts="nocache,direct"

## Network Configuration

Examples of some possible network configurations.
All guests support multiple network interfaces.

### Basic Example, Connected to 'public' virtual switch

    network0_type="virtio-net"
    network0_switch="public"

### Custom Mac Address

Please note that on first run, all network interfaces are assigned a static
mac address automatically by `vm-bhyve` if they don't have one. This mac address
is then written to the configuration file.

    network0_type="virtio-net"
    network0_switch="public"
    network0_mac="00:11:22:33:44:55"

### Custom Network Device

By default `vm-bhyve` will create a dynamic tap device for each interface. If you want
to do something complex, requiring manual network settings, this can be a problem as
the device doesn't exist until you start the guest.

By specifying a custom device you can configure this device yourself via `rc.conf`.
Note that I have left the `switch` configuration option out. If specified, the tap
device will be automatically attached to the virtual switch. If you have already configured
the custom device as required you may not want this, so can leave the switch settings out.

    network0_type="virtio-net"
    network0_dev="tap0"
