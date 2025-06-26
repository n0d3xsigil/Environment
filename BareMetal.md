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
root@archiso ~ # ping -3 -c 4 archlinux.org
PING archlinux.org (95.217.163.246) 56(84) bytes of data.
64 bytes from archlinux.org (95.217.163.246): icmp_seq=1 ttl=52 time=47.322 ms
64 bytes from archlinux.org (95.217.163.246): icmp_seq=2 ttl=52 time=53.098 ms
64 bytes from archlinux.org (95.217.163.246): icmp_seq=3 ttl=52 time=51.742 ms
64 bytes from archlinux.org (95.217.163.246): icmp_seq=4 ttl=52 time=51.150 ms

--- archlinux.org ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 47.322/50.828/53.098/2.143 ms
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

## Partitioning Disks
I need to be careful here, the documentation on the archlinux website states not to build using raid, but I want to so I'm going to try it. Anyway

First we can run `lsblk` to show what devices are available

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

So we can see that `md126` is `1.9T`. so we're going to partition this using `cfdisk`.

```shell
root@archiso ~ # cfdisk /dev/md126
```

### Boot partition
1. Select **`[   New   ]`** and press return to create the boot partition
2. Enter 5G as the partition size and press return on the keybaord
3. Select and **`[  Type  ]`** and press return to select the type
4. Find and select **`EFI System`** and press return on the keyboard
    - The type will change to `EFI System`

### Swap partition
1. Move down to select the _`Free Space`_
2. Select **`[   New   ]`** and press return to create the swap partition
3. Enter 256G as the partition size and press return on the keybaord
4. Select and **`[  Type  ]`** and press return to select the type
5. Find and select **`Linux swap`** and press return on the keyboard
    - The type will change to `Linux swap`
  

### Root filesystem
1. Move down to select the _`Free Space`_
2. Select **`[   New   ]`** and press return to create the boot partition
3. The system will default to the remaining storage, accept this by pressing return on the keyboard
4. Leave the type as the default `Linux filesystem`.

### Safe partition format
1. Select **`[  Write ]`** and press return on the keyboard
2. Type `yes` to the are you sure question
3. Finally select **`[  Quit  ]`** and press return

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
│ ├─md126p1 259:5    0     5G  0 part
│ ├─md126p2 259:6    0   256G  0 part
│ └─md126p3 259:7    0   1.6T  0 part
└─md127       9:127  0     0B  0
nvme1n1     259:1    0 953.9G  0 disk
├─md126       9:126  0   1.9T  0 raid0
│ ├─md126p1 259:5    0     5G  0 part
│ ├─md126p2 259:6    0   256G  0 part
│ └─md126p3 259:7    0   1.6T  0 part
└─md127       9:127  0     0B  0
```

Okay so now we have the following structure.

|     Device     |   Size   |           Description           |
|----------------|----------|---------------------------------|
| `/dev/md126p1` |      5Gb | EFI Boot partition              |
| `/dev/md126p2` |    256Gb | Linux swap parition             |
| `/dev/md126p3` |  1,638Gb | Linux `/` (`root`) file system  |

## Formatting partitions
### Root
The root partiton is the foundation of the system. We will use the latest revision of the `ext` format (`ext4`)

```shell
root@archiso ~ # mkfs.ext4 -v /dev/md126p3
mke2fs 1.47.2 (1-Jan-2025)
fs_types for mke2fs.conf resolution: 'ext4'
Discarding device blocks: done
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=16 blocks, Stripe width=32 blocks
107921408 inodes, 431681024 blocks
21584051 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2579496960
13174 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Filesystem UUID: 47e3872f-46c3-45c1-9075-b063fd355ae0
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,
        102400000, 214990848

Allocating group tables: done
Writing inode tables: done
Creating journal (262144 blocks): done
Writing superblocks and filesystem accounting information: done
```

### Swap
Next we will enable the swap patition usig `mkswap`

```shell
root@archiso ~ # mkswap --verbose /dev/md126p2
Setting up swapspace version 1, size = 256 GiB (274877902848 bytes)
no label, UUID=97e3a8be-7128-4cbe-8ddc-0dcccaca7594
```

### Boot
We are using an EFI partiton on GPT so we want to format the partition as `FAT32`

```shell
root@archiso ~ # mkfs.fat -v -F 32 /dev/md126p1
mkfs.fat 4.2 (2021-01-31)
/dev/md126p1 has 2 heads and 4 sectors per track,
hidden sectors 0x0800;
logical sector size is 512,
using 0xf8 media descriptor, with 10485760 sectors;
drive number 0x80;
filesystem has 2 32-bit FATs and 8 sectors per cluster.
FAT size is 10224 sectors, and provides 1308160 clusters.
There are 32 reserved sectors.
Volume ID is 20d7f9be, no volume label.
```

## Mounting filesystems
### Root
First we'll mount the root partition `/dev/md126p3` to `/mnt`

```shell
root@archiso ~ # mount -v /dev/md126p3 /mnt
mount: /dev/md126p3 mounted on /mnt.
```

### Boot
Next we will mount the boot parttion (`/dev/md126p1` to `/mnt/boot`). We haven't created `/mnt/boot` yet, `--mkdir` will handle this.

```shell
root@archiso ~ # mount -v --mkdir /dev/md126p1 /mnt/boot
mount: /dev/md126p1 mounted on /mnt/boot.
```

### Swap
Finally we don't mount the swap space, as much as we just enable it using `swapon`

```shell
root@archiso ~ # swapon -v /dev/md126p2
swapon: /dev/md126p2: found signature [pagesize=4096, signature=swap]
swapon: /dev/md126p2: pagesize=4096, swapsize=274877906944, devsize=274877906944
swapon /dev/md126p2
```



## Installing the base system
Okay, so we need to install the following at a minimum `base` `linux`, and  `linux-firmware`.

However, we also need a way to connect to the network and also edit files at a minimum. So I will include also `iwd`* and `vim`.

* I recall having issues with just having iwd, I may revist his later.


