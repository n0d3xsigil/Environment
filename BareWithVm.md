# Bare metal build with Virtualisation

## Contents

- [Guide](#guide)
- [Console keyboard layout](#console-keyboard-layout)
- [Verify boot mode](#verify-boot-mode)
- [Connect network (Wireless)](#connect-network-Wireless)
- [update the clock](update-the-clock)
- [Connect remotely](#connect-remotely)
- [Partitioning Disks](#partitioning-disks)
	- [Boot partition](#boot-partition)
	- [Swap partition](#swap-partition)
	- [Root filesystem](#root-filesystem)
	- [Home partition](#home-partition)
	- [ISOs partition](#isos-partition)
	- [VM partition](#vm-partition)
	- [Save partition format](#save-partition-format)
	- [Verify format](#verify-format)
- [Formatting partitions](#formatting-partitions)
	- `/boot`
	- `swap`
	- `/`
	- `/home`
	- `/var/lib/libvirt/isos`
	- `/var/lib/libvirt/images`
- [Mounting filesystems](#mounting-filesystems)
	- [Root](#root)
	- [Boot](#boot)
	- [Swap](#swap)
	- [Home](#home)
	- [ISOs](#isos)
	- [VMs](#vms)
	- [Verification](#verification)
- [Installing the base system](#installing-the-base-system)
- [Configure the system](#configure-the-system)
	- [Generate `/mnt/etc/fstab](#generate-mntetcfstab)
	- [chroot time](#chroot-time)
	- [Password time](#password-time)
	- [Timezone](#timezone)
	- [Locale](#locale)
	- [Set hostname](#set-hostname)
	- [bootloader](#bootloader)
	- [Reboot time](#reboot-time)
- [Success](#success)
- [Troubleshooting](#troubleshooting)]


## Guide

Start by following step 1.0 through 1.4


## Console keyboard layout

We will use UK.
```shell
root@archiso ~ # loadkeys uk
```

## Verify boot mode

```shell
root@archiso ~ # cat /sys/firmware/efi/fw_platform_size
64
```
Shows booted in UEFI mode with 64-bit x64 UEFI

## Connect network (Wireless)

Run `ip link` to get adapters
```shell
ip link
root@archiso ~ # ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s31f6: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN mode DEFAULT group default qlen 1000
    link/ether 21:2a:06:9f:00:fa brd ff:ff:ff:ff:ff:ff
    altname enx7c4d8f50ee17
4: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DORMANT group default qlen 1000
    link/ether 6d:50:8b:a1:1a:c9 brd ff:ff:ff:ff:ff:ff
```

To connect wireless follow guide here: [iwctl](https://wiki.archlinux.org/title/Iwctl)

Use `iwctl` to enter wireless configuration

then use `device list` to get a list of devices
```shell
root@archiso ~ # iwctl
NetworkConfigurationEnabled: disabled
StateDirectory: /var/lib/iwd
Version: 3.8
[iwd]# device list
                                    Devices
--------------------------------------------------------------------------------
  Name                  Address               Powered     Adapter     Mode
--------------------------------------------------------------------------------
  wlan0                 46:33:3e:7c:72:13     on          phy0        station


```

now we know the device name we can use `station _wlan0_ scan` to find access points.

```shell
[iwd]# station wlan0 scan
```
This won't show any results, but it will scan for AP's

Next we can perform `station _wlan0_ get-networks

```shell
[iwd]# station wlan0 get-networks
                               Available networks
--------------------------------------------------------------------------------
      Network name                      Security            Signal
--------------------------------------------------------------------------------
      SSID-abc                          psk                 ****
      Another SSID                      psk                 ****
      iPhone 14 Pro Max Ultra Max       psk                 ****

```


The beauty of iwd is that you can tab to autocompleted. Which is great for my SSID that is randomly generated!

To connect to the AP just `station _wlan0_ connect %SSID%`

```shell
[iwd]# station wlan0 connect SSID-abc
Type the network passprhase for SSID-abc psk
Passphrase: ***
[iwd]# quit
```

ping

For the purpose of setup we can leave it here and go back to setup.

perform a ping test to a host of your choice, I'm using `archlinux.org` partly because thats the recommendation, but also, I want to make sure I can reach the archlinux infrastructure.

```shell
root@archiso ~ # ping -3 -c 1 archlinux.org
PING archlinux.org (95.217.163.246) 56(84) bytes of data.
64 bytes from archlinux.org (95.217.163.246): icmp_seq=1 ttl=52 time=47.971 ms

--- archlinux.org ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 47.971/47.971/47.971/0.000 ms
```

Great, we have a connection. 


## update the clock

We use `timedatectl` to ensure the clock is sync'd

```shell
root@archiso ~ # timedatectl
               Local time: Thu 2025-06-26 10:07:36 UTC
           Universal time: Thu 2025-06-26 10:07:36 UTC
                 RTC time: Thu 2025-06-26 10:07:36
                Time zone: UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```

Great, Moving on...


## Connect remotely

I want to connect via **`SSH`** to this ArchISO. to do this I need the IP

```Shell
root@archiso ~ # ip addr | grep -i wlan0 | grep -i inet
    inet 192.168.1.21/24 metric 600 brd 192.168.1.255 scope global dynamic wlan0
```


Next I need to set the `root` password. 

```Shell
127 root@archiso ~ # passwd
New password:           password
Retype new password:    password
passwd: password updated successfully
```


So we now know our IP and our password is set, lets try connecting

```PowerShell
PS C:\Users\UserID> ssh root@192.168.1.21
The authenticity of host '192.168.1.21 (192.168.1.21)' can't be established.
ED25519 key fingerprint is SHA256:uvCDIgUHdr/PuN5ffwD9bniye8Kdg4tk-FhbFPeIJjtI.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.1.21' (ED25519) to the list of known hosts.
root@192.168.1.21's password:
To install Arch Linux follow the installation guide:
https://wiki.archlinux.org/title/Installation_guide

For Wi-Fi, authenticate to the wireless network using the iwctl utility.
For mobile broadband (WWAN) modems, connect with the mmcli utility.
Ethernet, WLAN and WWAN interfaces using DHCP should work automatically.

After connecting to the internet, the installation guide can be accessed
via the convenience script Installation_guide.


root@archiso ~ #
```


## Partitioning Disks

I need to be careful here, the documentation on the archlinux website states not to build using raid, but I want to so I'm going to try it. Anyway

First we can run `lsblk` to show what devices are available.

```shell
root@archiso ~ # lsblk
NAME    MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
loop0     7:0    0 853.9M  1 loop  /run/archiso/airootfs
sda       8:0    1  14.9G  0 disk
├─sda1    8:1    1  1023M  0 part
└─sda2    8:2    1   175M  0 part
nvme0n1 259:0    0 953.9G  0 disk
├─md126   9:126  0   1.9T  0 raid0
└─md127   9:127  0     0B  0
nvme1n1 259:1    0 953.9G  0 disk
├─md126   9:126  0   1.9T  0 raid0
└─md127   9:127  0     0B  0
```


I am fortunate, I am on a system that has a RAID controller that is supported by Linux. So we can see that `md126` is `1.9T`. so we're going to partition this using `cfdisk`.

```shell
root@archiso ~ # cfdisk /dev/md126
```


### Boot partition

1. Select **`[   New   ]`** and press return to create the boot partition
2. Enter 512M as the partition size and press return on the keybaord
3. Select and **`[  Type  ]`** and press return to select the type
4. Find and select **`EFI System`** and press return on the keyboard
    - The type will change to `EFI System`


### Swap partition

1. Move down to select the _`Free Space`_
2. Select **`[   New   ]`** and press return to create the swap partition
3. Enter 16G as the partition size and press return on the keybaord
4. Select and **`[  Type  ]`** and press return to select the type
5. Find and select **`Linux swap`** and press return on the keyboard
    - The type will change to `Linux swap`


### Root filesystem

1. Move down to select the _`Free Space`_
2. Select **`[   New   ]`** and press return to create the boot partition
3. Enter 16G as the partition size and press return on the keybaord
5. Leave the type as the default `Linux filesystem`.


### Home partition

1. Move down to select the _`Free Space`_
2. Select **`[   New   ]`** and press return to create the boot partition
3. Enter 100G as the partition size and press return on the keybaord
5. Leave the type as the default `Linux filesystem`.


### ISOs partition

1. Move down to select the _`Free Space`_
2. Select **`[   New   ]`** and press return to create the boot partition
3. Enter 100G as the partition size and press return on the keybaord
5. Leave the type as the default `Linux filesystem`.


### VM partition

1. Move down to select the _`Free Space`_
2. Select **`[   New   ]`** and press return to create the boot partition
4. The system will default to the remaining storage, accept this by pressing return on the keyboard
5. Leave the type as the default `Linux filesystem`.

### Safe partition format

1. Select **`[  Write ]`** and press return on the keyboard
2. Type `yes` to the are you sure question
3. Finally select **`[  Quit  ]`** and press return


### Verify format

Now we can run `lsblk` again to verify that the partitions have been created and saved correctly.

```shell
root@archiso ~ # lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
loop0         7:0    0 853.9M  1 loop  /run/archiso/airootfs
sda           8:0    1  14.9G  0 disk
├─sda1        8:1    1  1023M  0 part
└─sda2        8:2    1   175M  0 part
nvme0n1     259:0    0 953.9G  0 disk
├─md126       9:126  0   1.9T  0 raid0
│ ├─md126p1 259:2    0   512M  0 part
│ ├─md126p2 259:9    0    16G  0 part
│ ├─md126p3 259:10   0    50G  0 part
│ ├─md126p4 259:11   0   100G  0 part
│ ├─md126p5 259:12   0   100G  0 part
│ └─md126p6 259:13   0   1.6T  0 part
└─md127       9:127  0     0B  0
nvme1n1     259:1    0 953.9G  0 disk
├─md126       9:126  0   1.9T  0 raid0
│ ├─md126p1 259:2    0   512M  0 part
│ ├─md126p2 259:9    0    16G  0 part
│ ├─md126p3 259:10   0    50G  0 part
│ ├─md126p4 259:11   0   100G  0 part
│ ├─md126p5 259:12   0   100G  0 part
│ └─md126p6 259:13   0   1.6T  0 part
└─md127       9:127  0     0B  0
```


Okay so now we have the following structure.

|     Device     |   Size   |           Description           |            Mount            |    Format    |
|----------------|----------|---------------------------------|-----------------------------|--------------|
│ `/dev/md126p1` |     512M | EFI Boot partition              | `/boot`                     | **FAT32**    |
│ `/dev/md126p2` |      16G | Linux swap parition             | `[swap]`                    | **swap**     |
│ `/dev/md126p3` |      50G | Arch host system                | `/`                         | **ext4**     |
│ `/dev/md126p4` |     100G | Home partition                  | `/home`                     | **ext4**     |
│ `/dev/md126p5` |     100G | ISO library                     | `/var/lib/libvirt/isos`     | **ext4**     |
│ `/dev/md126p6` |     1.6T | VM disk images                  | `/var/lib/libvirt/images `  | **btrfs**    |



## Formatting partitions

### │ `/dev/md126p1` |     512M | EFI Boot partition              | `/boot`                     | **FAT32**    |

The boot partition will be formatted with **`FAT32`**.

```Shell
root@archiso ~ # mkfs.fat -v -F 32 /dev/md126p1
mkfs.fat 4.2 (2021-01-31)
/dev/md126p1 has 2 heads and 4 sectors per track,
hidden sectors 0x0800;
logical sector size is 512,
using 0xf8 media descriptor, with 1048576 sectors;
drive number 0x80;
filesystem has 2 32-bit FATs and 8 sectors per cluster.
FAT size is 1024 sectors, and provides 130812 clusters.
There are 32 reserved sectors.
Volume ID is 73e4e2f2, no volume label.
```


### │ `/dev/md126p2` |      16G | Linux swap parition             | `[swap]`                    | **swap**     |

The swap partition will be formatted with **`swap`**.

```Shell
root@archiso ~ # mkswap --verbose /dev/md126p2
Setting up swapspace version 1, size = 16 GiB (17179865088 bytes)
no label, UUID=19ad20c3-86d7-48ac-a673-f825f0400607
```


### │ `/dev/md126p3` |      50G | Arch host system                | `/`                         | **ext4**     |

The Arch host partition will be formatted with **`ext4`**.

```Shell
root@archiso ~ # mkfs.ext4 -v /dev/md126p3
mke2fs 1.47.2 (1-Jan-2025)
fs_types for mke2fs.conf resolution: 'ext4'
Discarding device blocks: done
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=16 blocks, Stripe width=32 blocks
3276800 inodes, 13107200 blocks
655360 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2162163712
400 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Filesystem UUID: 8cbce5d0-3ea1-463f-b03e-56e39245f8a9
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424

Allocating group tables: done
Writing inode tables: done
Creating journal (65536 blocks): done
Writing superblocks and filesystem accounting information: done
```

### │ `/dev/md126p4` |     100G | Home partition                  | `/home`                     | **ext4**     |

The home partition will be formatted with **`ext4`**.

```Shell
root@archiso ~ # mkfs.ext4 -v /dev/md126p4
mke2fs 1.47.2 (1-Jan-2025)
fs_types for mke2fs.conf resolution: 'ext4'
Discarding device blocks: done
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=16 blocks, Stripe width=32 blocks
6553600 inodes, 26214400 blocks
1310720 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2174746624
800 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Filesystem UUID: 00324105-a6e1-467e-a7b6-8e89b72dc41c
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424, 20480000, 23887872

Allocating group tables: done
Writing inode tables: done
Creating journal (131072 blocks): done
Writing superblocks and filesystem accounting information: done
```


### │ `/dev/md126p5` |     100G | ISO library                     | `/var/lib/libvirt/isos`     | **ext4**     |

The ISOs partition will be formatted with **`ext4`**.

```Shell
root@archiso ~ # mkfs.ext4 -v /dev/md126p5
mke2fs 1.47.2 (1-Jan-2025)
fs_types for mke2fs.conf resolution: 'ext4'
Discarding device blocks: done
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=16 blocks, Stripe width=32 blocks
6553600 inodes, 26214400 blocks
1310720 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2174746624
800 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Filesystem UUID: e4270575-1910-473c-a201-d3bbab5ddcee
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424, 20480000, 23887872

Allocating group tables: done
Writing inode tables: done
Creating journal (131072 blocks): done
Writing superblocks and filesystem accounting information: done
```


### │ `/dev/md126p6` |     1.6T | VM disk images                  | `/var/lib/libvirt/images `  | **btrfs**   |

And finally, the VM images partition will be formatted with **`btrfs`**.

```Shell
 127 root@archiso ~ # mkfs.btrfs -v /dev/md126p6
btrfs-progs v6.14
See https://btrfs.readthedocs.io for more information.

Performing full device TRIM /dev/md126p6 (1.60TiB) ...
NOTE: several default settings have changed in version 5.15, please make sure
      this does not affect your deployments:
      - DUP for metadata (-m dup)
      - enabled no-holes (-O no-holes)
      - enabled free-space-tree (-R free-space-tree)

Label:              (null)
UUID:               e6fbaa6c-6cb1-4bcb-b73d-ef3294a7d38d
Node size:          16384
Sector size:        4096        (CPU page size: 4096)
Filesystem size:    1.60TiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP               1.00GiB
  System:           DUP               8.00MiB
SSD detected:       yes
Zoned device:       no
Features:           extref, skinny-metadata, no-holes, free-space-tree
Checksum:           crc32c
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1     1.60TiB  /dev/md126p6
```



## Mounting filesystems

### Root

- **Partition**:      `/dev/md126p3`
- **Description**:    Arch host system
- **Mount Point**:    `/mnt`
- **Format**:         ext4

First we'll mount the root partition `/dev/md126p3` to `/mnt`

```shell
1 root@archiso ~ # mount -v /dev/md126p3 /mnt
mount: /dev/md126p3 mounted on /mnt.
```


### Boot

- **Partition**:      `/dev/md126p1`
- **Description**:    EFI Boot partition
- **Mount Point**:    `/boot`
- **Format**:         FAT32

Next we will mount the boot partition (`/dev/md126p1` to `/mnt/boot`). We haven't created `/mnt/boot` yet, `--mkdir` will handle this.

```shell
root@archiso ~ # mount -v --mkdir /dev/md126p1 /mnt/boot
mount: /dev/md126p1 mounted on /mnt/boot.
```





### Swap

- **Partition**:      `/dev/md126p2`
- **Description**:    Linux swap parition
- **Mount Point**:    N/A
- **Format**:         swap

Finally we don't mount the swap space, as much as we just enable it using `swapon`

```shell
root@archiso ~ # swapon -v /dev/md126p2
swapon: /dev/md126p2: found signature [pagesize=4096, signature=swap]
swapon: /dev/md126p2: pagesize=4096, swapsize=17179869184, devsize=17179869184
swapon /dev/md126p2
```


### Home

- **Partition**:      `/dev/md126p4`
- **Description**:    Home partition
- **Mount Point**:    `/mnt/home`
- **Format**:         ext4

```shell
root@archiso ~ # mount -v --mkdir /dev/md126p4 /mnt/home
mount: /dev/md126p4 mounted on /mnt/home.
```



### ISOs

- **Partition**:      `/dev/md126p5`
- **Description**:    ISO library
- **Mount Point**:    `/mnt/var/lib/libvirt/isos`
- **Format**:         ext4

```shell
root@archiso ~ # mount -v --mkdir /dev/md126p5 /mnt/var/lib/libvirt/isos
mount: /dev/md126p5 mounted on /mnt/var/lib/libvirt/isos.
```



### VMs

- **Partition**:      `/dev/md126p6`
- **Description**:    VM disk images
- **Mount Point**:    `/mnt/var/lib/libvirt/images`
- **Format**:         btrfs

```shell
root@archiso ~ # mount -v --mkdir /dev/md126p6 /mnt/var/lib/libvirt/images
mount: /dev/md126p6 mounted on /mnt/var/lib/libvirt/images.
```


### Verification

I just want to verify that the folders I expect have been created, I'm expecting to see **`/`**, **`/boot`**, **`/home`**, **`/var/lib/libvirt/images`**, and **`/var/lib/libvirt/isos`**.

```shell
root@archiso ~ # ls -laR /mnt | grep /mnt
/mnt:
/mnt/boot:
/mnt/home:
/mnt/home/lost+found:
/mnt/lost+found:
/mnt/var:
/mnt/var/lib:
/mnt/var/lib/libvirt:
/mnt/var/lib/libvirt/images:
/mnt/var/lib/libvirt/isos:
/mnt/var/lib/libvirt/isos/lost+found:
```


I'm happy with that we can also do some verification with `lsblk`.

```shell
root@archiso ~ # lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
loop0         7:0    0 853.9M  1 loop  /run/archiso/airootfs
sda           8:0    1  14.9G  0 disk
├─sda1        8:1    1  1023M  0 part
└─sda2        8:2    1   175M  0 part
nvme0n1     259:0    0 953.9G  0 disk
├─md126       9:126  0   1.9T  0 raid0
│ ├─md126p1 259:2    0   512M  0 part  /mnt/boot
│ ├─md126p2 259:9    0    16G  0 part  [SWAP]
│ ├─md126p3 259:10   0    50G  0 part  /mnt
│ ├─md126p4 259:11   0   100G  0 part  /mnt/home
│ ├─md126p5 259:12   0   100G  0 part  /mnt/var/lib/libvirt/isos
│ └─md126p6 259:13   0   1.6T  0 part  /mnt/var/lib/libvirt/images
└─md127       9:127  0     0B  0
nvme1n1     259:1    0 953.9G  0 disk
├─md126       9:126  0   1.9T  0 raid0
│ ├─md126p1 259:2    0   512M  0 part  /mnt/boot
│ ├─md126p2 259:9    0    16G  0 part  [SWAP]
│ ├─md126p3 259:10   0    50G  0 part  /mnt
│ ├─md126p4 259:11   0   100G  0 part  /mnt/home
│ ├─md126p5 259:12   0   100G  0 part  /mnt/var/lib/libvirt/isos
│ └─md126p6 259:13   0   1.6T  0 part  /mnt/var/lib/libvirt/images
```


I think I'm happy with that too. Onto installing the base 


## Installing the base system

Okay, so we need to install the following at a minimum `base` `linux`, and  `linux-firmware`. 

In addition to that we also want to make our life post build a little easier so I also install `iwd`, `vim`, `sudo`, `openssh`, `ufw`, `mdadm`, `xorg-server`, `xorg-xinit`, `openbox`, `xterm`, `rofi`, `lightdm`, and `lightdm-gtk-greeter`

```shell
1 root@archiso ~ # pacstrap -K /mnt base linux linux-firmware iwd vim sudo openssh ufw mdadm xorg-server xorg-xinit openbox xterm rofi lightdm lightdm-gtk-greeter
==> Creating install root at /mnt
==> Installing packages to /mnt
:: Synchronizing package databases...
 core is up to date
 extra is up to date
resolving dependencies...
:: There are 2 providers available for libxtables.so=12-64:
:: Repository core
   1) iptables  2) iptables-nft

Enter a number (default=1):
:: There are 3 providers available for initramfs:
:: Repository core
   1) mkinitcpio
:: Repository extra
   2) booster  3) dracut

Enter a number (default=1):
looking for conflicting packages...
warning: dependency cycle detected:
warning: systemd-libs will be installed before its libcap dependency

Packages (147) acl-2.3.2-1  archlinux-keyring-20250716-1  attr-2.5.2-1  audit-4.0.5-1  bash-5.3.0-1  binutils-2.44+r94+gfe459e33c676-1  brotli-1.1.0-3  bzip2-1.0.8-6  ca-certificates-20240618-1
               ca-certificates-mozilla-3.114-1  ca-certificates-utils-20240618-1  coreutils-9.7-1  cryptsetup-2.8.0-1  curl-8.15.0-1  dbus-1.16.2-1  dbus-broker-37-2  dbus-broker-units-37-2
               dbus-units-37-2  device-mapper-2.03.33-1  diffutils-3.12-2  e2fsprogs-1.47.3-1  ell-0.78-1  expat-2.7.1-1  file-5.46-4  filesystem-2025.05.03-1  findutils-4.10.0-3  gawk-5.3.2-1
               gcc-libs-15.1.1+r7+gf36ec88aa85a-1  gdbm-1.25-1  gettext-0.26-1  glib2-2.84.3-1  glibc-2.41+r48+g5cb575ca9a3d-1  gmp-6.3.0-2  gnulib-l10n-20241231-1  gnupg-2.4.8-1
               gnutls-3.8.10-1  gpgme-2.0.0-1  gpm-1.20.7.r38.ge82d1a6-6  grep-3.12-2  gzip-1.14-2  hwdata-0.397-1  iana-etc-20250612-1  icu-76.1-1  iproute2-6.15.0-1  iptables-1:1.8.11-2
               iputils-20250605-1  jansson-2.14.1-1  json-c-0.18-2  kbd-2.8.0-1  keyutils-1.6.3-3  kmod-34.2-1  krb5-1.21.3-2  leancrypto-1.5.1-1  libarchive-3.8.1-1  libassuan-3.0.0-1
               libbpf-1.5.1-1  libcap-2.76-1  libcap-ng-0.8.5-3  libedit-20250104_3.1-1  libelf-0.193-2  libevent-2.1.12-4  libffi-3.5.1-1  libgcrypt-1.11.1-1  libgpg-error-1.55-1
               libidn2-2.3.7-1  libksba-1.6.7-2  libldap-2.6.10-2  libmnl-1.0.5-2  libnetfilter_conntrack-1.0.9-2  libnfnetlink-1.0.2-2  libnftnl-1.2.9-1  libnghttp2-1.66.0-1
               libnghttp3-1.10.1-1  libnl-3.11.0-1  libnsl-2.0.1-1  libp11-kit-0.25.5-1  libpcap-1.10.5-3  libpsl-0.21.5-2  libsasl-2.1.28-5  libseccomp-2.5.6-1  libsecret-0.21.7-1
               libssh2-1.11.1-1  libsysprof-capture-48.0-5  libtasn1-4.20.0-1  libtirpc-1.3.6-2  libunistring-1.3-1  libusb-1.0.29-1  libverto-0.3.2-5  libxcrypt-4.4.38-1  libxml2-2.14.5-1
               licenses-20240728-1  linux-api-headers-6.15-1  linux-firmware-amdgpu-20250708-1  linux-firmware-atheros-20250708-1  linux-firmware-broadcom-20250708-1
               linux-firmware-cirrus-20250708-1  linux-firmware-intel-20250708-1  linux-firmware-mediatek-20250708-1  linux-firmware-nvidia-20250708-1  linux-firmware-other-20250708-1
               linux-firmware-radeon-20250708-1  linux-firmware-realtek-20250708-1  linux-firmware-whence-20250708-1  lmdb-0.9.33-1  lz4-1:1.10.0-2  mkinitcpio-39.2-3
               mkinitcpio-busybox-1.36.1-1  mpfr-4.2.2-1  ncurses-6.5-4  nettle-3.10.2-1  npth-1.8-1  openssl-3.5.1-1  p11-kit-0.25.5-1  pacman-7.0.0.r6.gc685ae6-6  pacman-mirrorlist-20250702-2
               pam-1.7.1-1  pambase-20230918-2  pciutils-3.14.0-1  pcre2-10.45-1  pinentry-1.3.1-5  popt-1.19-2  procps-ng-4.0.5-3  psmisc-23.7-1  readline-8.3.001-1  sed-4.9-3  shadow-4.18.0-1
               sqlite-3.50.3-1  systemd-257.7-1  systemd-libs-257.7-1  systemd-sysvcompat-257.7-1  tar-1.35-2  tpm2-tss-4.1.3-1  tzdata-2025b-1  util-linux-2.41.1-1  util-linux-libs-2.41.1-1
               vim-runtime-9.1.1552-1  xz-5.8.1-1  zlib-1:1.3.1-2  zstd-1.5.7-2  base-3-2  iwd-3.9-1  linux-6.15.7.arch1-1  linux-firmware-20250708-1  mdadm-4.4-1  openssh-10.0p1-3
               sudo-1.9.17.p1-1  vim-9.1.1552-1

Total Download Size:    641.12 MiB
Total Installed Size:  1171.10 MiB

:: Proceed with installation? [Y/n]
:: Retrieving packages...
 linux-6.15.7.arch1-1-x86_64                                                             141.2 MiB  11.2 MiB/s 00:13 [######################################################################] 100%  linux-firmware-intel-20250708-1-any                                                     104.4 MiB  5.25 MiB/s 00:20 [######################################################################] 100%  linux-firmware-nvidia-20250708-1-any                                                     98.8 MiB  3.79 MiB/s 00:26 [######################################################################] 100%  linux-firmware-atheros-20250708-1-any                                                    41.5 MiB  1535 KiB/s 00:28 [######################################################################] 100%  gcc-libs-15.1.1+r7+gf36ec88aa85a-1-x86_64                                                35.9 MiB  1270 KiB/s 00:29 [######################################################################] 100%  linux-firmware-amdgpu-20250708-1-any                                                     25.5 MiB  1528 KiB/s 00:17 [######################################################################] 100%  linux-firmware-other-20250708-1-any                                                      24.9 MiB  2.26 MiB/s 00:11 [######################################################################] 100%  linux-firmware-mediatek-20250708-1-any                                                   22.0 MiB  3.66 MiB/s 00:06 [######################################################################] 100%  linux-firmware-broadcom-20250708-1-any                                                   12.9 MiB  2.57 MiB/s 00:05 [######################################################################] 100%  icu-76.1-1-x86_64                                                                        11.4 MiB  2.63 MiB/s 00:04 [######################################################################] 100%  glibc-2.41+r48+g5cb575ca9a3d-1-x86_64                                                    10.0 MiB  2.58 MiB/s 00:04 [######################################################################] 100%  systemd-257.7-1-x86_64                                                                    8.8 MiB  2.77 MiB/s 00:03 [######################################################################] 100%  binutils-2.44+r94+gfe459e33c676-1-x86_64                                                  7.7 MiB  3.26 MiB/s 00:02 [######################################################################] 100%  vim-runtime-9.1.1552-1-x86_64                                                             7.4 MiB  3.45 MiB/s 00:02 [######################################################################] 100%  linux-firmware-realtek-20250708-1-any                                                     5.7 MiB  3.01 MiB/s 00:02 [######################################################################] 100%  openssl-3.5.1-1-x86_64                                                                    5.3 MiB  3.08 MiB/s 00:02 [######################################################################] 100%  util-linux-2.41.1-1-x86_64                                                                5.2 MiB  3.51 MiB/s 00:01 [######################################################################] 100%  glib2-2.84.3-1-x86_64                                                                     4.9 MiB  4.03 MiB/s 00:01 [######################################################################] 100%  gettext-0.26-1-x86_64                                                                     2.8 MiB  2.66 MiB/s 00:01 [######################################################################] 100%  gnupg-2.4.8-1-x86_64                                                                      2.8 MiB  3.13 MiB/s 00:01 [######################################################################] 100%  coreutils-9.7-1-x86_64                                                                    2.8 MiB  3.44 MiB/s 00:01 [######################################################################] 100%  linux-firmware-radeon-20250708-1-any                                                      2.3 MiB  3.75 MiB/s 00:01 [######################################################################] 100%  vim-9.1.1552-1-x86_64                                                                     2.3 MiB  4.81 MiB/s 00:00 [######################################################################] 100%  sqlite-3.50.3-1-x86_64                                                                    2.2 MiB  4.57 MiB/s 00:00 [######################################################################] 100%  bash-5.3.0-1-x86_64                                                                    1932.5 KiB  3.88 MiB/s 00:00 [######################################################################] 100%  sudo-1.9.17.p1-1-x86_64                                                                1887.8 KiB  4.14 MiB/s 00:00 [######################################################################] 100%  gnutls-3.8.10-1-x86_64                                                                 1805.6 KiB  4.87 MiB/s 00:00 [######################################################################] 100%  hwdata-0.397-1-any                                                                     1677.4 KiB  4.42 MiB/s 00:00 [######################################################################] 100%  linux-firmware-cirrus-20250708-1-any                                                   1653.2 KiB  5.51 MiB/s 00:00 [######################################################################] 100%  pcre2-10.45-1-x86_64                                                                   1619.7 KiB  4.36 MiB/s 00:00 [######################################################################] 100%  gawk-5.3.2-1-x86_64                                                                    1462.4 KiB  5.03 MiB/s 00:00 [######################################################################] 100%  leancrypto-1.5.1-1-x86_64                                                              1371.0 KiB  5.36 MiB/s 00:00 [######################################################################] 100%  linux-api-headers-6.15-1-x86_64                                                        1309.9 KiB  5.40 MiB/s 00:00 [######################################################################] 100%  krb5-1.21.3-2-x86_64                                                                   1309.9 KiB  4.19 MiB/s 00:00 [######################################################################] 100%  e2fsprogs-1.47.3-1-x86_64                                                              1265.5 KiB  4.51 MiB/s 00:00 [######################################################################] 100%  openssh-10.0p1-3-x86_64                                                                1265.3 KiB  5.33 MiB/s 00:00 [######################################################################] 100%  kbd-2.8.0-1-x86_64                                                                     1258.1 KiB  4.95 MiB/s 00:00 [######################################################################] 100%  shadow-4.18.0-1-x86_64                                                                 1230.1 KiB  5.07 MiB/s 00:00 [######################################################################] 100%  systemd-libs-257.7-1-x86_64                                                            1225.9 KiB  4.14 MiB/s 00:00 [######################################################################] 100%  archlinux-keyring-20250716-1-any                                                       1214.6 KiB  4.46 MiB/s 00:00 [######################################################################] 100%  curl-8.15.0-1-x86_64                                                                   1213.6 KiB  5.56 MiB/s 00:00 [######################################################################] 100%  ncurses-6.5-4-x86_64                                                                   1158.7 KiB  5.26 MiB/s 00:00 [######################################################################] 100%  iproute2-6.15.0-1-x86_64                                                               1126.6 KiB  4.98 MiB/s 00:00 [######################################################################] 100%  tpm2-tss-4.1.3-1-x86_64                                                                 938.8 KiB  3.04 MiB/s 00:00 [######################################################################] 100%  pacman-7.0.0.r6.gc685ae6-6-x86_64                                                       924.5 KiB  3.41 MiB/s 00:00 [######################################################################] 100%  procps-ng-4.0.5-3-x86_64                                                                873.6 KiB  7.23 MiB/s 00:00 [######################################################################] 100%  xz-5.8.1-1-x86_64                                                                       812.1 KiB  4.96 MiB/s 00:00 [######################################################################] 100%  cryptsetup-2.8.0-1-x86_64                                                               799.8 KiB  5.17 MiB/s 00:00 [######################################################################] 100%  libxml2-2.14.5-1-x86_64                                                                 794.6 KiB  4.15 MiB/s 00:00 [######################################################################] 100%  tar-1.35-2-x86_64                                                                       777.6 KiB  4.44 MiB/s 00:00 [######################################################################] 100%  libcap-2.76-1-x86_64                                                                    774.9 KiB  5.08 MiB/s 00:00 [######################################################################] 100%  libunistring-1.3-1-x86_64                                                               722.3 KiB  5.38 MiB/s 00:00 [######################################################################] 100%  libgcrypt-1.11.1-1-x86_64                                                               715.2 KiB  4.99 MiB/s 00:00 [######################################################################] 100%  libelf-0.193-2-x86_64                                                                   614.8 KiB  3.87 MiB/s 00:00 [######################################################################] 100%  iwd-3.9-1-x86_64                                                                        598.4 KiB  3.46 MiB/s 00:00 [######################################################################] 100%  pam-1.7.1-1-x86_64                                                                      595.5 KiB  3.40 MiB/s 00:00 [######################################################################] 100%  libarchive-3.8.1-1-x86_64                                                               558.3 KiB  3.25 MiB/s 00:00 [######################################################################] 100%  zstd-1.5.7-2-x86_64                                                                     510.6 KiB  3.96 MiB/s 00:00 [######################################################################] 100%  util-linux-libs-2.41.1-1-x86_64                                                         491.3 KiB  3.04 MiB/s 00:00 [######################################################################] 100%  findutils-4.10.0-3-x86_64                                                               475.6 KiB  3.08 MiB/s 00:00 [######################################################################] 100%  nettle-3.10.2-1-x86_64                                                                  459.6 KiB  3.10 MiB/s 00:00 [######################################################################] 100%  libp11-kit-0.25.5-1-x86_64                                                              456.9 KiB  5.79 MiB/s 00:00 [######################################################################] 100%  gmp-6.3.0-2-x86_64                                                                      442.9 KiB  4.08 MiB/s 00:00 [######################################################################] 100%  mpfr-4.2.2-1-x86_64                                                                     436.8 KiB  3.28 MiB/s 00:00 [######################################################################] 100%  file-5.46-4-x86_64                                                                      432.3 KiB  3.25 MiB/s 00:00 [######################################################################] 100%  iptables-1:1.8.11-2-x86_64                                                              419.0 KiB  3.12 MiB/s 00:00 [######################################################################] 100%  libnl-3.11.0-1-x86_64                                                                   410.3 KiB  3.45 MiB/s 00:00 [######################################################################] 100%  readline-8.3.001-1-x86_64                                                               409.7 KiB  3.88 MiB/s 00:00 [######################################################################] 100%  audit-4.0.5-1-x86_64                                                                    405.3 KiB  4.12 MiB/s 00:00 [######################################################################] 100%  mdadm-4.4-1-x86_64                                                                      403.5 KiB  3.94 MiB/s 00:00 [######################################################################] 100%  iana-etc-20250612-1-any                                                                 399.3 KiB  4.29 MiB/s 00:00 [######################################################################] 100%  ca-certificates-mozilla-3.114-1-x86_64                                                  398.6 KiB  4.19 MiB/s 00:00 [######################################################################] 100%  brotli-1.1.0-3-x86_64                                                                   389.6 KiB  3.92 MiB/s 00:00 [######################################################################] 100%  tzdata-2025b-1-x86_64                                                                   347.2 KiB  3.65 MiB/s 00:00 [######################################################################] 100%  dbus-1.16.2-1-x86_64                                                                    346.1 KiB  3.19 MiB/s 00:00 [######################################################################] 100%  diffutils-3.12-2-x86_64                                                                 341.9 KiB  3.63 MiB/s 00:00 [######################################################################] 100%  gpgme-2.0.0-1-x86_64                                                                    317.7 KiB  3.23 MiB/s 00:00 [######################################################################] 100%  libpcap-1.10.5-3-x86_64                                                                 288.1 KiB  2.93 MiB/s 00:00 [######################################################################] 100%  libldap-2.6.10-2-x86_64                                                                 282.0 KiB  2.73 MiB/s 00:00 [######################################################################] 100%  device-mapper-2.03.33-1-x86_64                                                          280.2 KiB  2.28 MiB/s 00:00 [######################################################################] 100%  mkinitcpio-busybox-1.36.1-1-x86_64                                                      277.5 KiB  2.98 MiB/s 00:00 [######################################################################] 100%  libgpg-error-1.55-1-x86_64                                                              269.1 KiB  3.46 MiB/s 00:00 [######################################################################] 100%  libevent-2.1.12-4-x86_64                                                                267.4 KiB  4.35 MiB/s 00:00 [######################################################################] 100%  psmisc-23.7-1-x86_64                                                                    259.8 KiB  3.96 MiB/s 00:00 [######################################################################] 100%  libbpf-1.5.1-1-x86_64                                                                   254.7 KiB  3.60 MiB/s 00:00 [######################################################################] 100%  gdbm-1.25-1-x86_64                                                                      253.9 KiB  3.76 MiB/s 00:00 [######################################################################] 100%  libssh2-1.11.1-1-x86_64                                                                 252.6 KiB  4.11 MiB/s 00:00 [######################################################################] 100%  ell-0.78-1-x86_64                                                                       250.0 KiB  4.07 MiB/s 00:00 [######################################################################] 100%  grep-3.12-2-x86_64                                                                      235.6 KiB  3.54 MiB/s 00:00 [######################################################################] 100%  p11-kit-0.25.5-1-x86_64                                                                 223.0 KiB  2.94 MiB/s 00:00 [######################################################################] 100%  sed-4.9-3-x86_64                                                                        210.5 KiB  2.64 MiB/s 00:00 [######################################################################] 100%  libsecret-0.21.7-1-x86_64                                                               188.2 KiB  3.53 MiB/s 00:00 [######################################################################] 100%  pinentry-1.3.1-5-x86_64                                                                 184.5 KiB  3.16 MiB/s 00:00 [######################################################################] 100%  libtirpc-1.3.6-2-x86_64                                                                 172.8 KiB  3.13 MiB/s 00:00 [######################################################################] 100%  lz4-1:1.10.0-2-x86_64                                                                   156.3 KiB  2.77 MiB/s 00:00 [######################################################################] 100%  dbus-broker-37-2-x86_64                                                                 146.8 KiB  2.14 MiB/s 00:00 [######################################################################] 100%  libsasl-2.1.28-5-x86_64                                                                 146.6 KiB  1928 KiB/s 00:00 [######################################################################] 100%  pciutils-3.14.0-1-x86_64                                                                144.7 KiB  2.28 MiB/s 00:00 [######################################################################] 100%  libksba-1.6.7-2-x86_64                                                                  142.2 KiB  2.20 MiB/s 00:00 [######################################################################] 100%  libidn2-2.3.7-1-x86_64                                                                  139.8 KiB  2.35 MiB/s 00:00 [######################################################################] 100%  iputils-20250605-1-x86_64                                                               139.7 KiB  2.39 MiB/s 00:00 [######################################################################] 100%  acl-2.3.2-1-x86_64                                                                      137.8 KiB  2.36 MiB/s 00:00 [######################################################################] 100%  gpm-1.20.7.r38.ge82d1a6-6-x86_64                                                        135.7 KiB  2.65 MiB/s 00:00 [######################################################################] 100%  libtasn1-4.20.0-1-x86_64                                                                133.4 KiB  1853 KiB/s 00:00 [######################################################################] 100%  kmod-34.2-1-x86_64                                                                      130.3 KiB  2.12 MiB/s 00:00 [######################################################################] 100%  gnulib-l10n-20241231-1-any                                                              124.0 KiB  2.05 MiB/s 00:00 [######################################################################] 100%  expat-2.7.1-1-x86_64                                                                    116.5 KiB  2.28 MiB/s 00:00 [######################################################################] 100%  lmdb-0.9.33-1-x86_64                                                                    116.3 KiB  1736 KiB/s 00:00 [######################################################################] 100%  libedit-20250104_3.1-1-x86_64                                                           112.3 KiB  2.44 MiB/s 00:00 [######################################################################] 100%  libassuan-3.0.0-1-x86_64                                                                112.2 KiB  1969 KiB/s 00:00 [######################################################################] 100%  licenses-20240728-1-any                                                                 105.7 KiB  1762 KiB/s 00:00 [######################################################################] 100%  keyutils-1.6.3-3-x86_64                                                                 102.0 KiB  1379 KiB/s 00:00 [######################################################################] 100%  libnghttp2-1.66.0-1-x86_64                                                               92.8 KiB  1600 KiB/s 00:00 [######################################################################] 100%  zlib-1:1.3.1-2-x86_64                                                                    92.3 KiB  1710 KiB/s 00:00 [######################################################################] 100%  libseccomp-2.5.6-1-x86_64                                                                88.7 KiB  2.02 MiB/s 00:00 [######################################################################] 100%  jansson-2.14.1-1-x86_64                                                                  87.3 KiB  1617 KiB/s 00:00 [######################################################################] 100%  libpsl-0.21.5-2-x86_64                                                                   86.8 KiB  1471 KiB/s 00:00 [######################################################################] 100%  gzip-1.14-2-x86_64                                                                       86.7 KiB  1769 KiB/s 00:00 [######################################################################] 100%  libxcrypt-4.4.38-1-x86_64                                                                84.6 KiB  1227 KiB/s 00:00 [######################################################################] 100%  popt-1.19-2-x86_64                                                                       76.3 KiB  1157 KiB/s 00:00 [######################################################################] 100%  libusb-1.0.29-1-x86_64                                                                   76.3 KiB  1589 KiB/s 00:00 [######################################################################] 100%  libnghttp3-1.10.1-1-x86_64                                                               73.0 KiB  1089 KiB/s 00:00 [######################################################################] 100%  libnftnl-1.2.9-1-x86_64                                                                  69.9 KiB  1457 KiB/s 00:00 [######################################################################] 100%  attr-2.5.2-1-x86_64                                                                      68.4 KiB  1368 KiB/s 00:00 [######################################################################] 100%  json-c-0.18-2-x86_64                                                                     58.5 KiB  2.20 MiB/s 00:00 [######################################################################] 100%  mkinitcpio-39.2-3-any                                                                    64.2 KiB   917 KiB/s 00:00 [######################################################################] 100%  bzip2-1.0.8-6-x86_64                                                                     58.4 KiB  2.04 MiB/s 00:00 [######################################################################] 100%  libsysprof-capture-48.0-5-x86_64                                                         49.3 KiB  1121 KiB/s 00:00 [######################################################################] 100%  libnetfilter_conntrack-1.0.9-2-x86_64                                                    47.6 KiB  1534 KiB/s 00:00 [######################################################################] 100%  libffi-3.5.1-1-x86_64                                                                    46.7 KiB  1140 KiB/s 00:00 [######################################################################] 100%  libcap-ng-0.8.5-3-x86_64                                                                 41.6 KiB  1487 KiB/s 00:00 [######################################################################] 100%  linux-firmware-whence-20250708-1-any                                                     39.0 KiB  1000 KiB/s 00:00 [######################################################################] 100%  npth-1.8-1-x86_64                                                                        28.2 KiB  1227 KiB/s 00:00 [######################################################################] 100%  libnsl-2.0.1-1-x86_64                                                                    21.7 KiB   804 KiB/s 00:00 [######################################################################] 100%  libverto-0.3.2-5-x86_64                                                                  18.3 KiB   523 KiB/s 00:00 [######################################################################] 100%  libnfnetlink-1.0.2-2-x86_64                                                              17.0 KiB   415 KiB/s 00:00 [######################################################################] 100%  filesystem-2025.05.03-1-any                                                              14.5 KiB   373 KiB/s 00:00 [######################################################################] 100%  libmnl-1.0.5-2-x86_64                                                                    11.2 KiB   509 KiB/s 00:00 [######################################################################] 100%  ca-certificates-utils-20240618-1-any                                                     10.8 KiB   270 KiB/s 00:00 [######################################################################] 100%  pacman-mirrorlist-20250702-2-any                                                          7.8 KiB   356 KiB/s 00:00 [######################################################################] 100%  systemd-sysvcompat-257.7-1-x86_64                                                         6.1 KiB   291 KiB/s 00:00 [######################################################################] 100%  pambase-20230918-2-any                                                                    3.0 KiB  82.4 KiB/s 00:00 [######################################################################] 100%  dbus-broker-units-37-2-x86_64                                                             2.4 KiB   115 KiB/s 00:00 [######################################################################] 100%  linux-firmware-20250708-1-any                                                             2.4 KiB   108 KiB/s 00:00 [######################################################################] 100%  base-3-2-any                                                                              2.3 KiB   100 KiB/s 00:00 [######################################################################] 100%  dbus-units-37-2-x86_64                                                                    2.2 KiB  83.8 KiB/s 00:00 [######################################################################] 100%  ca-certificates-20240618-1-any                                                            2.1 KiB  83.4 KiB/s 00:00 [######################################################################] 100%  Total (147/147)                                                                         641.1 MiB  15.5 MiB/s 00:41 [######################################################################] 100%
(147/147) checking keys in keyring                                                                                   [######################################################################] 100%
(147/147) checking package integrity                                                                                 [######################################################################] 100%
(147/147) loading package files                                                                                      [######################################################################] 100%
(147/147) checking for file conflicts                                                                                [######################################################################] 100%
(147/147) checking available disk space                                                                              [######################################################################] 100%
:: Processing package changes...
(  1/147) installing iana-etc                                                                                        [######################################################################] 100%
(  2/147) installing filesystem                                                                                      [######################################################################] 100%
(  3/147) installing linux-api-headers                                                                               [######################################################################] 100%
(  4/147) installing tzdata                                                                                          [######################################################################] 100%
Optional dependencies for tzdata
    bash: for tzselect [pending]
    glibc: for zdump, zic [pending]
(  5/147) installing glibc                                                                                           [######################################################################] 100%
Optional dependencies for glibc
    gd: for memusagestat
    perl: for mtrace
(  6/147) installing gcc-libs                                                                                        [######################################################################] 100%
(  7/147) installing ncurses                                                                                         [######################################################################] 100%
Optional dependencies for ncurses
    bash: for ncursesw6-config [pending]
(  8/147) installing readline                                                                                        [######################################################################] 100%
(  9/147) installing bash                                                                                            [######################################################################] 100%
Optional dependencies for bash
    bash-completion: for tab completion
( 10/147) installing acl                                                                                             [######################################################################] 100%
( 11/147) installing attr                                                                                            [######################################################################] 100%
( 12/147) installing gmp                                                                                             [######################################################################] 100%
( 13/147) installing zlib                                                                                            [######################################################################] 100%
( 14/147) installing sqlite                                                                                          [######################################################################] 100%
( 15/147) installing util-linux-libs                                                                                 [######################################################################] 100%
Optional dependencies for util-linux-libs
    python: python bindings to libmount
( 16/147) installing e2fsprogs                                                                                       [######################################################################] 100%
Optional dependencies for e2fsprogs
    lvm2: for e2scrub
    util-linux: for e2scrub [pending]
    smtp-forwarder: for e2scrub_fail script
( 17/147) installing keyutils                                                                                        [######################################################################] 100%
( 18/147) installing gdbm                                                                                            [######################################################################] 100%
( 19/147) installing openssl                                                                                         [######################################################################] 100%
Optional dependencies for openssl
    ca-certificates [pending]
    perl
( 20/147) installing libsasl                                                                                         [######################################################################] 100%
( 21/147) installing libldap                                                                                         [######################################################################] 100%
( 22/147) installing libevent                                                                                        [######################################################################] 100%
Optional dependencies for libevent
    python: event_rpcgen.py
( 23/147) installing libverto                                                                                        [######################################################################] 100%
( 24/147) installing lmdb                                                                                            [######################################################################] 100%
( 25/147) installing krb5                                                                                            [######################################################################] 100%
( 26/147) installing libcap-ng                                                                                       [######################################################################] 100%
( 27/147) installing audit                                                                                           [######################################################################] 100%
Optional dependencies for audit
    libldap: for audispd-zos-remote [installed]
    sh: for augenrules [installed]
( 28/147) installing libxcrypt                                                                                       [######################################################################] 100%
( 29/147) installing libtirpc                                                                                        [######################################################################] 100%
( 30/147) installing libnsl                                                                                          [######################################################################] 100%
( 31/147) installing pambase                                                                                         [######################################################################] 100%
( 32/147) installing libgpg-error                                                                                    [######################################################################] 100%
( 33/147) installing libgcrypt                                                                                       [######################################################################] 100%
( 34/147) installing lz4                                                                                             [######################################################################] 100%
( 35/147) installing xz                                                                                              [######################################################################] 100%
( 36/147) installing zstd                                                                                            [######################################################################] 100%
( 37/147) installing systemd-libs                                                                                    [######################################################################] 100%
( 38/147) installing pam                                                                                             [######################################################################] 100%
( 39/147) installing libcap                                                                                          [######################################################################] 100%
( 40/147) installing coreutils                                                                                       [######################################################################] 100%
( 41/147) installing bzip2                                                                                           [######################################################################] 100%
( 42/147) installing libseccomp                                                                                      [######################################################################] 100%
( 43/147) installing file                                                                                            [######################################################################] 100%
( 44/147) installing findutils                                                                                       [######################################################################] 100%
( 45/147) installing mpfr                                                                                            [######################################################################] 100%
( 46/147) installing gawk                                                                                            [######################################################################] 100%
( 47/147) installing pcre2                                                                                           [######################################################################] 100%
Optional dependencies for pcre2
    sh: for pcre2-config [installed]
( 48/147) installing grep                                                                                            [######################################################################] 100%
( 49/147) installing procps-ng                                                                                       [######################################################################] 100%
( 50/147) installing sed                                                                                             [######################################################################] 100%
( 51/147) installing tar                                                                                             [######################################################################] 100%
( 52/147) installing gnulib-l10n                                                                                     [######################################################################] 100%
( 53/147) installing libunistring                                                                                    [######################################################################] 100%
( 54/147) installing icu                                                                                             [######################################################################] 100%
( 55/147) installing libxml2                                                                                         [######################################################################] 100%
Optional dependencies for libxml2
    python: Python bindings
( 56/147) installing gettext                                                                                         [######################################################################] 100%
Optional dependencies for gettext
    git: for autopoint infrastructure updates
    appstream: for appstream support
( 57/147) installing hwdata                                                                                          [######################################################################] 100%
( 58/147) installing kmod                                                                                            [######################################################################] 100%
( 59/147) installing pciutils                                                                                        [######################################################################] 100%
Optional dependencies for pciutils
    which: for update-pciids
    grep: for update-pciids [installed]
    curl: for update-pciids [pending]
( 60/147) installing psmisc                                                                                          [######################################################################] 100%
( 61/147) installing shadow                                                                                          [######################################################################] 100%
( 62/147) installing util-linux                                                                                      [######################################################################] 100%
Optional dependencies for util-linux
    words: default dictionary for look
( 63/147) installing gzip                                                                                            [######################################################################] 100%
Optional dependencies for gzip
    less: zless support
    util-linux: zmore support [installed]
    diffutils: zdiff/zcmp support [pending]
( 64/147) installing licenses                                                                                        [######################################################################] 100%
( 65/147) installing libtasn1                                                                                        [######################################################################] 100%
( 66/147) installing libffi                                                                                          [######################################################################] 100%
( 67/147) installing libp11-kit                                                                                      [######################################################################] 100%
( 68/147) installing p11-kit                                                                                         [######################################################################] 100%
( 69/147) installing ca-certificates-utils                                                                           [######################################################################] 100%
( 70/147) installing ca-certificates-mozilla                                                                         [######################################################################] 100%
( 71/147) installing ca-certificates                                                                                 [######################################################################] 100%
( 72/147) installing brotli                                                                                          [######################################################################] 100%
( 73/147) installing libidn2                                                                                         [######################################################################] 100%
( 74/147) installing libnghttp2                                                                                      [######################################################################] 100%
( 75/147) installing libnghttp3                                                                                      [######################################################################] 100%
( 76/147) installing libpsl                                                                                          [######################################################################] 100%
( 77/147) installing libssh2                                                                                         [######################################################################] 100%
( 78/147) installing curl                                                                                            [######################################################################] 100%
( 79/147) installing nettle                                                                                          [######################################################################] 100%
( 80/147) installing leancrypto                                                                                      [######################################################################] 100%
( 81/147) installing gnutls                                                                                          [######################################################################] 100%
Optional dependencies for gnutls
    tpm2-tss: support for TPM2 wrapped keys [pending]
( 82/147) installing libksba                                                                                         [######################################################################] 100%
( 83/147) installing libusb                                                                                          [######################################################################] 100%
( 84/147) installing libassuan                                                                                       [######################################################################] 100%
( 85/147) installing libsysprof-capture                                                                              [######################################################################] 100%
( 86/147) installing glib2                                                                                           [######################################################################] 100%
Optional dependencies for glib2
    dconf: GSettings storage backend
    glib2-devel: development tools
    gvfs: most gio functionality
( 87/147) installing json-c                                                                                          [######################################################################] 100%
( 88/147) installing tpm2-tss                                                                                        [######################################################################] 100%
( 89/147) installing libsecret                                                                                       [######################################################################] 100%
Optional dependencies for libsecret
    org.freedesktop.secrets: secret storage backend
( 90/147) installing pinentry                                                                                        [######################################################################] 100%
Optional dependencies for pinentry
    gcr: GNOME backend
    gtk3: GTK backend
    qt5-x11extras: Qt5 backend
    kwayland5: Qt5 backend
    kguiaddons: Qt6 backend
    kwindowsystem: Qt6 backend
( 91/147) installing npth                                                                                            [######################################################################] 100%
( 92/147) installing gnupg                                                                                           [######################################################################] 100%
Optional dependencies for gnupg
    pcsclite: for using scdaemon not with the gnupg internal card driver
( 93/147) installing gpgme                                                                                           [######################################################################] 100%
( 94/147) installing libarchive                                                                                      [######################################################################] 100%
( 95/147) installing pacman-mirrorlist                                                                               [######################################################################] 100%
( 96/147) installing device-mapper                                                                                   [######################################################################] 100%
( 97/147) installing popt                                                                                            [######################################################################] 100%
( 98/147) installing cryptsetup                                                                                      [######################################################################] 100%
( 99/147) installing expat                                                                                           [######################################################################] 100%
(100/147) installing dbus                                                                                            [######################################################################] 100%
(101/147) installing dbus-broker                                                                                     [######################################################################] 100%
(102/147) installing dbus-broker-units                                                                               [######################################################################] 100%
(103/147) installing dbus-units                                                                                      [######################################################################] 100%
(104/147) installing kbd                                                                                             [######################################################################] 100%
(105/147) installing libelf                                                                                          [######################################################################] 100%
(106/147) installing systemd                                                                                         [######################################################################] 100%
Initializing machine ID from random generator.
Creating group 'sys' with GID 3.
Creating group 'mem' with GID 8.
Creating group 'ftp' with GID 11.
Creating group 'mail' with GID 12.
Creating group 'log' with GID 19.
Creating group 'smmsp' with GID 25.
Creating group 'proc' with GID 26.
Creating group 'games' with GID 50.
Creating group 'lock' with GID 54.
Creating group 'network' with GID 90.
Creating group 'floppy' with GID 94.
Creating group 'scanner' with GID 96.
Creating group 'power' with GID 98.
Creating group 'nobody' with GID 65534.
Creating group 'adm' with GID 999.
Creating group 'wheel' with GID 998.
Creating group 'utmp' with GID 997.
Creating group 'audio' with GID 996.
Creating group 'disk' with GID 995.
Creating group 'input' with GID 994.
Creating group 'kmem' with GID 993.
Creating group 'kvm' with GID 992.
Creating group 'lp' with GID 991.
Creating group 'optical' with GID 990.
Creating group 'render' with GID 989.
Creating group 'sgx' with GID 988.
Creating group 'storage' with GID 987.
Creating group 'tty' with GID 5.
Creating group 'uucp' with GID 986.
Creating group 'video' with GID 985.
Creating group 'users' with GID 984.
Creating group 'groups' with GID 983.
Creating group 'systemd-journal' with GID 982.
Creating group 'rfkill' with GID 981.
Creating group 'bin' with GID 1.
Creating user 'bin' (n/a) with UID 1 and GID 1.
Creating group 'daemon' with GID 2.
Creating user 'daemon' (n/a) with UID 2 and GID 2.
Creating user 'mail' (n/a) with UID 8 and GID 12.
Creating user 'ftp' (n/a) with UID 14 and GID 11.
Creating group 'http' with GID 33.
Creating user 'http' (n/a) with UID 33 and GID 33.
Creating user 'nobody' (Kernel Overflow User) with UID 65534 and GID 65534.
Creating group 'dbus' with GID 81.
Creating user 'dbus' (System Message Bus) with UID 81 and GID 81.
Creating group 'systemd-coredump' with GID 980.
Creating user 'systemd-coredump' (systemd Core Dumper) with UID 980 and GID 980.
Creating group 'systemd-network' with GID 979.
Creating user 'systemd-network' (systemd Network Management) with UID 979 and GID 979.
Creating group 'systemd-oom' with GID 978.
Creating user 'systemd-oom' (systemd Userspace OOM Killer) with UID 978 and GID 978.
Creating group 'systemd-journal-remote' with GID 977.
Creating user 'systemd-journal-remote' (systemd Journal Remote) with UID 977 and GID 977.
Creating group 'systemd-resolve' with GID 976.
Creating user 'systemd-resolve' (systemd Resolver) with UID 976 and GID 976.
Creating group 'systemd-timesync' with GID 975.
Creating user 'systemd-timesync' (systemd Time Synchronization) with UID 975 and GID 975.
Creating group 'tss' with GID 974.
Creating user 'tss' (tss user for tpm2) with UID 974 and GID 974.
Creating group 'uuidd' with GID 973.
Creating user 'uuidd' (UUID generator helper daemon) with UID 973 and GID 973.
Created symlink '/etc/systemd/system/getty.target.wants/getty@tty1.service' → '/usr/lib/systemd/system/getty@.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/remote-fs.target' → '/usr/lib/systemd/system/remote-fs.target'.
Created symlink '/etc/systemd/system/sockets.target.wants/systemd-userdbd.socket' → '/usr/lib/systemd/system/systemd-userdbd.socket'.
Optional dependencies for systemd
    libmicrohttpd: systemd-journal-gatewayd and systemd-journal-remote
    quota-tools: kernel-level quota management
    systemd-sysvcompat: symlink package to provide sysvinit binaries [pending]
    systemd-ukify: combine kernel and initrd into a signed Unified Kernel Image
    polkit: allow administration as unprivileged user
    curl: systemd-journal-upload, machinectl pull-tar and pull-raw [installed]
    gnutls: systemd-journal-gatewayd and systemd-journal-remote [installed]
    qrencode: show QR codes
    iptables: firewall features [pending]
    libarchive: convert DDIs to tarballs [installed]
    libbpf: support BPF programs [pending]
    libpwquality: check password quality
    libfido2: unlocking LUKS2 volumes with FIDO2 token
    libp11-kit: support PKCS#11 [installed]
    tpm2-tss: unlocking LUKS2 volumes with TPM2 [installed]
(107/147) installing pacman                                                                                          [######################################################################] 100%
Optional dependencies for pacman
    base-devel: required to use makepkg
    perl-locale-gettext: translation support in makepkg-template
(108/147) installing archlinux-keyring                                                                               [######################################################################] 100%
==> Appending keys from archlinux.gpg...
==> Locally signing trusted keys in keyring...
  -> Locally signed 5 keys.
==> Importing owner trust values...
gpg: setting ownertrust to 4
gpg: setting ownertrust to 4
gpg: setting ownertrust to 4
gpg: inserting ownertrust of 4
gpg: setting ownertrust to 4
==> Disabling revoked keys in keyring...
  -> Disabled 50 keys.
==> Updating trust database...
gpg: Note: third-party key signatures using the SHA1 algorithm are rejected
gpg: (use option "--allow-weak-key-signatures" to override)
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   5  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: depth: 1  valid:   5  signed: 102  trust: 0-, 0q, 0n, 5m, 0f, 0u
gpg: depth: 2  valid:  75  signed:  19  trust: 75-, 0q, 0n, 0m, 0f, 0u
gpg: next trustdb check due at 2025-08-18
(109/147) installing systemd-sysvcompat                                                                              [######################################################################] 100%
(110/147) installing iputils                                                                                         [######################################################################] 100%
(111/147) installing libmnl                                                                                          [######################################################################] 100%
(112/147) installing libnftnl                                                                                        [######################################################################] 100%
(113/147) installing libnl                                                                                           [######################################################################] 100%
(114/147) installing libpcap                                                                                         [######################################################################] 100%
(115/147) installing libnfnetlink                                                                                    [######################################################################] 100%
(116/147) installing libnetfilter_conntrack                                                                          [######################################################################] 100%
(117/147) installing iptables                                                                                        [######################################################################] 100%
(118/147) installing libbpf                                                                                          [######################################################################] 100%
(119/147) installing iproute2                                                                                        [######################################################################] 100%
Optional dependencies for iproute2
    db5.3: userspace arp daemon
    linux-atm: ATM support
    python: for routel
(120/147) installing base                                                                                            [######################################################################] 100%
Optional dependencies for base
    linux: bare metal support [pending]
(121/147) installing mkinitcpio-busybox                                                                              [######################################################################] 100%
(122/147) installing jansson                                                                                         [######################################################################] 100%
(123/147) installing binutils                                                                                        [######################################################################] 100%
Optional dependencies for binutils
    debuginfod: for debuginfod server/client functionality
(124/147) installing diffutils                                                                                       [######################################################################] 100%
(125/147) installing mkinitcpio                                                                                      [######################################################################] 100%
Optional dependencies for mkinitcpio
    xz: Use lzma or xz compression for the initramfs image [installed]
    bzip2: Use bzip2 compression for the initramfs image [installed]
    lzop: Use lzo compression for the initramfs image
    lz4: Use lz4 compression for the initramfs image [installed]
    mkinitcpio-nfs-utils: Support for root filesystem on NFS
    systemd-ukify: alternative UKI generator
(126/147) installing linux                                                                                           [######################################################################] 100%
Optional dependencies for linux
    linux-firmware: firmware images needed for some devices [pending]
    scx-scheds: to use sched-ext schedulers
    wireless-regdb: to set the correct wireless channels of your country
(127/147) installing linux-firmware-whence                                                                           [######################################################################] 100%
(128/147) installing linux-firmware-amdgpu                                                                           [######################################################################] 100%
(129/147) installing linux-firmware-atheros                                                                          [######################################################################] 100%
(130/147) installing linux-firmware-broadcom                                                                         [######################################################################] 100%
(131/147) installing linux-firmware-cirrus                                                                           [######################################################################] 100%
(132/147) installing linux-firmware-intel                                                                            [######################################################################] 100%
(133/147) installing linux-firmware-mediatek                                                                         [######################################################################] 100%
(134/147) installing linux-firmware-nvidia                                                                           [######################################################################] 100%
(135/147) installing linux-firmware-other                                                                            [######################################################################] 100%
(136/147) installing linux-firmware-radeon                                                                           [######################################################################] 100%
(137/147) installing linux-firmware-realtek                                                                          [######################################################################] 100%
(138/147) installing linux-firmware                                                                                  [######################################################################] 100%
Optional dependencies for linux-firmware
    linux-firmware-liquidio: Firmware for Cavium LiquidIO server adapters
    linux-firmware-marvell: Firmware for Marvell devices
    linux-firmware-mellanox: Firmware for Mellanox Spectrum switches
    linux-firmware-nfp: Firmware for Netronome Flow Processors
    linux-firmware-qcom: Firmware for Qualcomm SoCs
    linux-firmware-qlogic: Firmware for QLogic devices
(139/147) installing ell                                                                                             [######################################################################] 100%
(140/147) installing iwd                                                                                             [######################################################################] 100%
Optional dependencies for iwd
    qrencode: for displaying QR code after DPP is started
(141/147) installing vim-runtime                                                                                     [######################################################################] 100%
Optional dependencies for vim-runtime
    sh: support for some tools and macros [installed]
    python: demoserver example tool
    gawk: mve tools upport [installed]
(142/147) installing gpm                                                                                             [######################################################################] 100%
(143/147) installing vim                                                                                             [######################################################################] 100%
Optional dependencies for vim
    python: Python language support
    ruby: Ruby language support
    lua: Lua language support
    perl: Perl language support
    tcl: Tcl language support
(144/147) installing sudo                                                                                            [######################################################################] 100%
(145/147) installing libedit                                                                                         [######################################################################] 100%
(146/147) installing openssh                                                                                         [######################################################################] 100%
Optional dependencies for openssh
    libfido2: FIDO/U2F support
    sh: for ssh-copy-id and findssl.sh [installed]
    x11-ssh-askpass: input passphrase in X
    xorg-xauth: X11 forwarding
(147/147) installing mdadm                                                                                           [######################################################################] 100%
Optional dependencies for mdadm
    bash: mdcheck [installed]
:: Running post-transaction hooks...
( 1/13) Creating system user accounts...
Creating group 'alpm' with GID 972.
Creating user 'alpm' (Arch Linux Package Management) with UID 972 and GID 972.
( 2/13) Updating journal message catalog...
( 3/13) Reloading system manager configuration...
  Skipped: Running in chroot.
( 4/13) Reloading user manager configuration...
  Skipped: Running in chroot.
( 5/13) Updating udev hardware database...
( 6/13) Applying kernel sysctl settings...
  Skipped: Running in chroot.
( 7/13) Creating temporary files...
( 8/13) Reloading device manager configuration...
  Skipped: Running in chroot.
( 9/13) Arming ConditionNeedsUpdate...
(10/13) Rebuilding certificate stores...
(11/13) Updating module dependencies...
(12/13) Updating linux initcpios...
==> Building image from preset: /etc/mkinitcpio.d/linux.preset: 'default'
==> Using default configuration file: '/etc/mkinitcpio.conf'
  -> -k /boot/vmlinuz-linux -g /boot/initramfs-linux.img
==> Starting build: '6.15.7-arch1-1'
  -> Running build hook: [base]
  -> Running build hook: [udev]
  -> Running build hook: [autodetect]
  -> Running build hook: [microcode]
  -> Running build hook: [modconf]
  -> Running build hook: [kms]
  -> Running build hook: [keyboard]
  -> Running build hook: [keymap]
  -> Running build hook: [consolefont]
==> WARNING: consolefont: no font found in configuration
  -> Running build hook: [block]
  -> Running build hook: [filesystems]
  -> Running build hook: [fsck]
==> Generating module dependencies
==> Creating zstd-compressed initcpio image: '/boot/initramfs-linux.img'
  -> Early uncompressed CPIO image generation successful
==> Initcpio image generation successful
==> Building image from preset: /etc/mkinitcpio.d/linux.preset: 'fallback'
==> Using default configuration file: '/etc/mkinitcpio.conf'
  -> -k /boot/vmlinuz-linux -g /boot/initramfs-linux-fallback.img -S autodetect
==> Starting build: '6.15.7-arch1-1'
  -> Running build hook: [base]
  -> Running build hook: [udev]
  -> Running build hook: [microcode]
  -> Running build hook: [modconf]
  -> Running build hook: [kms]
==> WARNING: Possibly missing firmware for module: 'ast'
  -> Running build hook: [keyboard]
==> WARNING: Possibly missing firmware for module: 'xhci_pci_renesas'
  -> Running build hook: [keymap]
  -> Running build hook: [consolefont]
==> WARNING: consolefont: no font found in configuration
  -> Running build hook: [block]
==> WARNING: Possibly missing firmware for module: 'wd719x'
==> WARNING: Possibly missing firmware for module: 'qla1280'
==> WARNING: Possibly missing firmware for module: 'qed'
==> WARNING: Possibly missing firmware for module: 'bfa'
==> WARNING: Possibly missing firmware for module: 'aic94xx'
==> WARNING: Possibly missing firmware for module: 'qla2xxx'
  -> Running build hook: [filesystems]
  -> Running build hook: [fsck]
==> Generating module dependencies
==> Creating zstd-compressed initcpio image: '/boot/initramfs-linux-fallback.img'
  -> Early uncompressed CPIO image generation successful
==> Initcpio image generation successful
(13/13) Reloading system bus configuration...
  Skipped: Running in chroot.
pacstrap -K /mnt base linux linux-firmware iwd vim sudo openssh mdadm  32.77s user 25.66s system 64% cpu 1:31.12 total
```

**_Note_**: I'm going to keep this in for the time being for later review, however, this is not required by any measure ;)


## Configure the sytem

Lets create the fstab using `genfstab` tool


### Generate `/mnt/etc/fstab`

```shell
root@archiso ~ # genfstab -U /mnt >> /mnt/etc/fstab
```


### chroot time

Now, we can finally step in to our system, with safety glasses, high viz and safety shoes on. 

```shell
root@archiso ~ # arch-chroot /mnt
[root@archiso /]#
```

Notice the big change. The prompt `root@archiso ~ #` became `[root@archiso /]#` :)


### Password time

Okay, we are now at the stage where we can put a password on the system. We can do that with `passwd`

```shell
[root@archiso /]# passwd
New password: notmypassword
Retype new password: notmypassword
passwd: password updated successfully
```


### Timezone

we need to set our time zone by creating a symbolic link.

```shell
[root@archiso /]# ln -sfv /usr/share/zoneinfo/Europe/London /etc/localtime
'/etc/localtime' -> '/usr/share/zoneinfo/Europe/London'
```


We also want to synchronise our system to the hardware clock.

```shell
[root@archiso /]# hwclock -vw
hwclock from util-linux 2.41.1
System Time: 1753209475.042348
Trying to open: /dev/rtc0
Using the rtc interface to the clock.
Assuming hardware clock is kept in UTC time.
RTC type: 'rtc_cmos'
Using delay: 0.500000 seconds
1753209475.500000 is close enough to 1753209475.500000 (0.000000 < 0.001000)
Set RTC to 1753209475 (1753209475 + 0; refsystime = 1753209475.000000)
Setting Hardware Clock to 18:37:55 = 1753209475 seconds since 1969
ioctl(RTC_SET_TIME) was successful.
Not adjusting drift factor because the --update-drift option was not used.
New /etc/adjtime data:
0.000000 1753209475 0.000000
1753209475
UTC
```


### Locale

we can use `vim` to edit the local file under `/etc/locale.conf`.

Before:

```shell
[root@archiso /]# cat /etc/locale.gen | grep "en_GB"
#en_GB.UTF-8 UTF-8
#en_GB ISO-8859-1
[root@archiso /]# vim /etc/locale.gen
```


Find the locale for your country / region. For example mine is `en_GB.UTF-8 UTF-8`. Then uncomment by remiving the `#`

If using vim, you can use `:x` to save the file and exit.

After:

```shell
[root@archiso /]# vim /etc/locale.gen
[...]
[root@archiso /]# cat /etc/locale.gen | grep -i en_gb
en_GB.UTF-8 UTF-8
#en_GB ISO-8859-1
[root@archiso /]#
```


Then you can perform the locale gen

```shell
[root@archiso /]# locale-gen
Generating locales...
  en_GB.UTF-8... done
Generation complete.
```


Next we need to create the LANG variable

```shell
[root@archiso /]# echo "LANG=en_GB.UTF-8" > /etc/locale.conf; cat /etc/locale.conf
LANG=en_GB.UTF-8
[root@archiso /]#
```


We also want to set the kemap perminantly

```shell
[root@archiso /]#  echo "KEYMAP=uk" > /etc/vconsole.conf; cat /etc/vconsole.conf
KEYMAP=uk
```


### Set hostname

And we want to create the hostname. I'm going to use `archibold` this time.

```shell
[root@archiso /]# echo "archibold" > /etc/hostname; cat /etc/hostname
archibold
[root@archiso /]#
```


### bootloader

Let's verify that our `boot` partition is mounted, is formatted as `vfat`

```shell
[root@archiso /]# mount | grep boot
/dev/md126p1 on /boot type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro)
```


We no want to verify it is atleast 512mb

```shell
[root@archiso /]# df -h boot
Filesystem      Size  Used Avail Use% Mounted on
/dev/md126p1    511M  189M  323M  37% /boot
```

Now to start the boot loader installation

```shell
[root@archiso /]# bootctl install
Created "/boot/EFI".
Created "/boot/EFI/systemd".
Created "/boot/EFI/BOOT".
Created "/boot/loader".
Created "/boot/loader/keys".
Created "/boot/loader/entries".
Created "/boot/EFI/Linux".
Copied "/usr/lib/systemd/boot/efi/systemd-bootx64.efi" to "/boot/EFI/systemd/systemd-bootx64.efi".
Copied "/usr/lib/systemd/boot/efi/systemd-bootx64.efi" to "/boot/EFI/BOOT/BOOTX64.EFI".
⚠️ Mount point '/boot' which backs the random seed file is world accessible, which is a security hole! ⚠️
⚠️ Random seed file '/boot/loader/.#bootctlrandom-seed2e9d1f0a5927f3bf' is world accessible, which is a security hole! ⚠️
Random seed file /boot/loader/random-seed successfully written (32 bytes).
````


**`<MOVE "item" WHEN "WhenIremember">`**
Obviously we don't want security holes., we'll come back to this but it is to do with the configuraiton of the chrooted environment. We can fix by closing down the permissions later

```shell
chmod 0700 /boot
chmod 0700 /boot/loader
chmod 0600 /boot/loader/random-seed
```
**`</MOVE "item" WHEN "WhenIremember">`**


Updating `loader.conf`

```shell
[root@archiso /]# vim /boot/loader/loader.conf; cat /boot/loader/loader.conf
default archibold
timeout 0
console-mode max
editor no
```


Lets set the compression to `gzip` and enable the hooks

```shell
[root@archiso /]# vim /etc/mkinitcpio.conf; grep -E 'gzip|HOOKS' /etc/mkinitcpio.conf
# HOOKS
# This is the most important setting in this file.  The HOOKS control the
# order in which HOOKS are added.  Run 'mkinitcpio -H <hook name>' for
#    HOOKS=(base)
#    HOOKS=(base udev autodetect modconf block filesystems fsck)
#    HOOKS=(base udev modconf block filesystems fsck)
#    HOOKS=(base udev modconf keyboard keymap consolefont block mdadm_udev encrypt filesystems fsck)
#    HOOKS=(base udev modconf block lvm2 filesystems fsck)
#    HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)
#HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
HOOKS=(base systemd autodetect modconf block mdadm_udev filesystems keyboard fsck)
# is used for Linux ≥ 5.9 and gzip compression is used for Linux < 5.9.
COMPRESSION="gzip"
```


configure `linux.preset`

```shell
[root@archiso /]# vim /etc/mkinitcpio.d/linux.preset; cat /etc/mkinitcpio.d/linux.preset
# mkinitcpio preset file for the 'linux' package

#ALL_config="/etc/mkinitcpio.conf"
#ALL_kver="/boot/vmlinuz-linux"

#PRESETS=('default' 'fallback')

#default_config="/etc/mkinitcpio.conf"
#default_image="/boot/initramfs-linux.img"
#default_uki="/efi/EFI/Linux/arch-linux.efi"
#default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"

#fallback_config="/etc/mkinitcpio.conf"
#fallback_image="/boot/initramfs-linux-fallback.img"
#fallback_uki="/efi/EFI/Linux/arch-linux-fallback.efi"
#fallback_options="-S autodetect"

PRESETS=('default')

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

default_uki="/boot/EFI/Linux/archibold.efi"
```


Grab the uuid for the root partition

```shell
[root@archiso /]# blkid -s PARTUUID -o value /dev/md126p3
75bd02ea-c59a-45be-8b64-e38e088c68ba
```


fix the kernel cmdline

```shell
[root@archiso /]# echo "root=PARTUUID=75bd02ea-c59a-45be-8b64-e38e088c68ba rw quiet loglevel=3" > /etc/kernel/cmdline
[root@archiso /]# cat /etc/kernel/cmdline
root=PARTUUID=75bd02ea-c59a-45be-8b64-e38e088c68ba rw quiet loglevel=3
```


Rebuild UKI

```shell
[root@archiso /]# mkinitcpio -p linux
==> Building image from preset: /etc/mkinitcpio.d/linux.preset: 'default'
==> Using configuration file: '/etc/mkinitcpio.conf'
  -> -k /boot/vmlinuz-linux -c /etc/mkinitcpio.conf -U /boot/EFI/Linux/archibold.efi
==> Starting build: '6.15.7-arch1-1'
  -> Running build hook: [base]
  -> Running build hook: [systemd]
  -> Running build hook: [autodetect]
  -> Running build hook: [modconf]
  -> Running build hook: [block]
  -> Running build hook: [mdadm_udev]
  -> Running build hook: [filesystems]
  -> Running build hook: [keyboard]
  -> Running build hook: [fsck]
==> Generating module dependencies
==> Creating gzip-compressed initcpio image
  -> Early uncompressed CPIO image generation successful
==> Initcpio image generation successful
==> Creating unified kernel image: '/boot/EFI/Linux/archibold.efi'
  -> Using cmdline file: '/etc/kernel/cmdline'
==> Unified kernel image generation successful
```


Create the boot entry

```shell
[root@archiso /]# vim /boot/loader/entries/archibold.conf; cat /boot/loader/entries/archibold.conf
title   Arch Linux (RAID-0 UKI)
efi     /EFI/Linux/archibold.efi
``


verify boot entries

```shell
[root@archiso /]# bootctl list
         type: Boot Loader Specification Type #2 (.efi)
        title: Arch Linux (default) (not reported/new)
           id: archibold.efi
       source: /boot//EFI/Linux/archibold.efi (on the EFI System Partition)
     sort-key: arch
      version: 6.15.3-arch1-1
        linux: /boot//EFI/Linux/archibold.efi
      options: root=PARTUUID=6bbc60fc-9fb1-436b-bca1-c46db43a54e4 rw quiet loglevel=3

         type: Boot Loader Specification Type #1 (.conf)
        title: Arch Linux (RAID-0 UKI) (not reported/new)
           id: archibold.conf
       source: /boot//loader/entries/archibold.conf (on the EFI System Partition)
          efi: /boot//EFI/Linux/archibold.efi
```


Verify arch is available

```shell
[root@archiso /]# ls -lh /boot/EFI/Linux/archibold.efi
-rwxr-xr-x 1 root root 26M Jun 25 13:42 /boot/EFI/Linux/archibold.efi
```


Verify arch is in the loader entries

```shell
[root@archiso /]# ls /boot/loader/entries/
archibold.conf
```


Verify the selected entry

```shell
[root@archiso /]# bootctl status
System:
Not booted with EFI

Available Boot Loaders on ESP:
          ESP: /boot
         File: ├─/EFI/systemd/systemd-bootx64.efi (systemd-boot 257.7-1-arch)
               └─/EFI/BOOT/BOOTX64.EFI (systemd-boot 257.7-1-arch)

Boot Loader Entries:
        $BOOT: /boot
        token: arch

Default Boot Loader Entry:
         type: Boot Loader Specification Type #2 (.efi)
        title: Arch Linux
           id: archibold.efi
       source: /boot//EFI/Linux/archibold.efi (on the EFI System Partition)
     sort-key: arch
      version: 6.15.7-arch1-1
        linux: /boot//EFI/Linux/archibold.efi
      options: root=PARTUUID=75bd02ea-c59a-45be-8b64-e38e088c68ba rw quiet loglevel=3
```


### Reboot time.

```shell
[root@archiso /]# exit
exit
arch-chroot /mnt  41.51s user 34.29s system 0% cpu 2:34:03.92 total
```

```shell
root@archiso ~ # shutdown -h now
```



## Success

This process has been tested multiple times and works each time, and it will do until I need it most :D




## Troubleshooting

Troubleshooting can be done via `arch-chroot` should boot issues occour. 
Set keyboard layout


```shell
root@archiso ~ # loadkeys uk
```

Conenct the wireless

```
root@archiso ~ # iwctl
NetworkConfigurationEnabled: disabled
StateDirectory: /var/lib/iwd
Version: 3.8
[iwd]# station wlan0 connect SSID-abc
Type the network passprhase for SSID-abc psk
Passphrase: ***
[iwd]# quit
```

Test the network connection

```shell
root@archiso ~ # ping -3 -c 1 archlinux.org
PING archlinux.org (95.217.163.246) 56(84) bytes of data.
64 bytes from archlinux.org (95.217.163.246): icmp_seq=1 ttl=52 time=47.401 ms

--- archlinux.org ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 47.401/47.401/47.401/0.000 ms
```

Mount the root filesystem

```shell
root@archiso ~ # mount /dev/md126p3 /mnt
```

mount the boot partition

```shell
root@archiso ~ # mount /dev/md126p1 /mnt/boot
```

finally chroot into the system

```shell
root@archiso ~ # arch-chroot /mnt
[root@archiso /]#
```
















