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

*I recall having issues with just having iwd, I may revist his later.

```shell
root@archiso ~ # pacstrap -K /mnt base linux linux-firmware iwd vim
==> Creating install root at /mnt
gpg: /mnt/etc/pacman.d/gnupg/trustdb.gpg: trustdb created
gpg: no ultimately trusted keys found
gpg: starting migration from earlier GnuPG versions
gpg: porting secret keys from '/mnt/etc/pacman.d/gnupg/secring.gpg' to gpg-agent
gpg: migration succeeded
==> Generating pacman master key. This may take some time.
gpg: Generating pacman keyring master key...
gpg: directory '/mnt/etc/pacman.d/gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/mnt/etc/pacman.d/gnupg/openpgp-revocs.d/C26C39A00635199302FD074F97D4B53F0B233098.rev'
gpg: Done
==> Updating trust database...
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
==> Installing packages to /mnt
:: Synchronizing package databases...
 core                                                   116.5 KiB   577 KiB/s 00:00 [################################################] 100%
 extra                                                    7.8 MiB  7.33 MiB/s 00:01 [################################################] 100%
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

Packages (143) acl-2.3.2-1  archlinux-keyring-20250430.1-1  attr-2.5.2-1  audit-4.0.5-1  bash-5.2.037-5  binutils-2.44+r94+gfe459e33c676-1
               brotli-1.1.0-3  bzip2-1.0.8-6  ca-certificates-20240618-1  ca-certificates-mozilla-3.113-1
               ca-certificates-utils-20240618-1  coreutils-9.7-1  cryptsetup-2.8.0-1  curl-8.14.1-1  dbus-1.16.2-1  dbus-broker-37-2
               dbus-broker-units-37-2  dbus-units-37-2  device-mapper-2.03.32-1  diffutils-3.12-2  e2fsprogs-1.47.2-2  ell-0.78-1
               expat-2.7.1-1  file-5.46-4  filesystem-2025.05.03-1  findutils-4.10.0-2  gawk-5.3.2-1  gcc-libs-15.1.1+r7+gf36ec88aa85a-1
               gdbm-1.25-1  gettext-0.25-1  glib2-2.84.3-1  glibc-2.41+r48+g5cb575ca9a3d-1  gmp-6.3.0-2  gnulib-l10n-20241231-1
               gnupg-2.4.8-1  gnutls-3.8.9-1  gpgme-2.0.0-1  gpm-1.20.7.r38.ge82d1a6-6  grep-3.12-2  gzip-1.14-2  hwdata-0.396-1
               iana-etc-20250612-1  icu-76.1-1  iproute2-6.15.0-1  iptables-1:1.8.11-2  iputils-20250605-1  jansson-2.14.1-1
               json-c-0.18-2  kbd-2.8.0-1  keyutils-1.6.3-3  kmod-34.2-1  krb5-1.21.3-1  leancrypto-1.4.0-1  libarchive-3.8.1-1
               libassuan-3.0.0-1  libbpf-1.5.1-1  libcap-2.76-1  libcap-ng-0.8.5-3  libelf-0.193-2  libevent-2.1.12-4  libffi-3.5.0-1
               libgcrypt-1.11.1-1  libgpg-error-1.55-1  libidn2-2.3.7-1  libksba-1.6.7-2  libldap-2.6.10-1  libmnl-1.0.5-2
               libnetfilter_conntrack-1.0.9-2  libnfnetlink-1.0.2-2  libnftnl-1.2.9-1  libnghttp2-1.66.0-1  libnghttp3-1.10.1-1
               libnl-3.11.0-1  libnsl-2.0.1-1  libp11-kit-0.25.5-1  libpcap-1.10.5-3  libpsl-0.21.5-2  libsasl-2.1.28-5
               libseccomp-2.5.6-1  libsecret-0.21.7-1  libssh2-1.11.1-1  libsysprof-capture-48.0-5  libtasn1-4.20.0-1  libtirpc-1.3.6-2
               libunistring-1.3-1  libusb-1.0.29-1  libverto-0.3.2-5  libxcrypt-4.4.38-1  libxml2-2.14.4-2  licenses-20240728-1
               linux-api-headers-6.15-1  linux-firmware-amdgpu-20250613.12fe085f-9  linux-firmware-atheros-20250613.12fe085f-9
               linux-firmware-broadcom-20250613.12fe085f-9  linux-firmware-cirrus-20250613.12fe085f-9
               linux-firmware-intel-20250613.12fe085f-9  linux-firmware-mediatek-20250613.12fe085f-9
               linux-firmware-nvidia-20250613.12fe085f-9  linux-firmware-other-20250613.12fe085f-9
               linux-firmware-radeon-20250613.12fe085f-9  linux-firmware-realtek-20250613.12fe085f-9
               linux-firmware-whence-20250613.12fe085f-9  lmdb-0.9.33-1  lz4-1:1.10.0-2  mkinitcpio-39.2-3  mkinitcpio-busybox-1.36.1-1
               mpfr-4.2.2-1  ncurses-6.5-4  nettle-3.10.1-1  npth-1.8-1  openssl-3.5.0-1  p11-kit-0.25.5-1  pacman-7.0.0.r6.gc685ae6-6
               pacman-mirrorlist-20250522-1  pam-1.7.1-1  pambase-20230918-2  pciutils-3.14.0-1  pcre2-10.45-1  pinentry-1.3.1-5
               popt-1.19-2  procps-ng-4.0.5-3  psmisc-23.7-1  readline-8.2.013-2  sed-4.9-3  shadow-4.17.4-1  sqlite-3.50.1-1
               systemd-257.7-1  systemd-libs-257.7-1  systemd-sysvcompat-257.7-1  tar-1.35-2  tpm2-tss-4.1.3-1  tzdata-2025b-1
               util-linux-2.41.1-1  util-linux-libs-2.41.1-1  vim-runtime-9.1.1431-1  xz-5.8.1-1  zlib-1:1.3.1-2  zstd-1.5.7-2  base-3-2
               iwd-3.9-1  linux-6.15.3.arch1-1  linux-firmware-20250613.12fe085f-9  vim-9.1.1431-1

Total Download Size:    635.79 MiB
Total Installed Size:  1153.15 MiB

:: Proceed with installation? [Y/n]
:: Retrieving packages...
 linux-6.15.3.arch1-1-x86_64                            141.2 MiB  14.3 MiB/s 00:10 [################################################] 100%
 linux-firmware-intel-20250613.12fe085f-9-any           104.5 MiB  6.53 MiB/s 00:16 [################################################] 100%
 linux-firmware-nvidia-20250613.12fe085f-9-any           98.8 MiB  4.38 MiB/s 00:23 [################################################] 100%
 linux-firmware-amdgpu-20250613.12fe085f-9-any           24.3 MiB  3.35 MiB/s 00:07 [################################################] 100%
 linux-firmware-atheros-20250613.12fe085f-9-any          41.5 MiB  1742 KiB/s 00:24 [################################################] 100%
 gcc-libs-15.1.1+r7+gf36ec88aa85a-1-x86_64               35.9 MiB  1476 KiB/s 00:25 [################################################] 100%
 linux-firmware-other-20250613.12fe085f-9-any            24.8 MiB  1662 KiB/s 00:15 [################################################] 100%
 linux-firmware-mediatek-20250613.12fe085f-9-any         22.0 MiB  5.78 MiB/s 00:04 [################################################] 100%
 linux-firmware-broadcom-20250613.12fe085f-9-any         12.9 MiB  3.60 MiB/s 00:04 [################################################] 100%
 icu-76.1-1-x86_64                                       11.4 MiB  3.50 MiB/s 00:03 [################################################] 100%
 glibc-2.41+r48+g5cb575ca9a3d-1-x86_64                   10.0 MiB  3.03 MiB/s 00:03 [################################################] 100%
 systemd-257.7-1-x86_64                                   8.8 MiB  2.70 MiB/s 00:03 [################################################] 100%
 binutils-2.44+r94+gfe459e33c676-1-x86_64                 7.7 MiB  3.25 MiB/s 00:02 [################################################] 100%
 vim-runtime-9.1.1431-1-x86_64                            7.5 MiB  3.66 MiB/s 00:02 [################################################] 100%
 linux-firmware-realtek-20250613.12fe085f-9-any           5.3 MiB  3.22 MiB/s 00:02 [################################################] 100%
 openssl-3.5.0-1-x86_64                                   5.2 MiB  3.65 MiB/s 00:01 [################################################] 100%
 util-linux-2.41.1-1-x86_64                               5.2 MiB  3.83 MiB/s 00:01 [################################################] 100%
 glib2-2.84.3-1-x86_64                                    4.9 MiB  4.00 MiB/s 00:01 [################################################] 100%
 gettext-0.25-1-x86_64                                    2.8 MiB  2.85 MiB/s 00:01 [################################################] 100%
 gnupg-2.4.8-1-x86_64                                     2.8 MiB  3.48 MiB/s 00:01 [################################################] 100%
 coreutils-9.7-1-x86_64                                   2.8 MiB  3.65 MiB/s 00:01 [################################################] 100%
 linux-firmware-radeon-20250613.12fe085f-9-any            2.3 MiB  4.07 MiB/s 00:01 [################################################] 100%
 vim-9.1.1431-1-x86_64                                    2.3 MiB  5.07 MiB/s 00:00 [################################################] 100%
 sqlite-3.50.1-1-x86_64                                   2.2 MiB  4.46 MiB/s 00:01 [################################################] 100%
 bash-5.2.037-5-x86_64                                 1845.9 KiB  4.46 MiB/s 00:00 [################################################] 100%
 gnutls-3.8.9-1-x86_64                                 1796.1 KiB  5.07 MiB/s 00:00 [################################################] 100%
 hwdata-0.396-1-any                                    1675.6 KiB  5.60 MiB/s 00:00 [################################################] 100%
 linux-firmware-cirrus-20250613.12fe085f-9-any         1653.3 KiB  5.05 MiB/s 00:00 [################################################] 100%
 pcre2-10.45-1-x86_64                                  1619.7 KiB  5.63 MiB/s 00:00 [################################################] 100%
 gawk-5.3.2-1-x86_64                                   1462.4 KiB  3.90 MiB/s 00:00 [################################################] 100%
 krb5-1.21.3-1-x86_64                                  1310.1 KiB  4.88 MiB/s 00:00 [################################################] 100%
 linux-api-headers-6.15-1-x86_64                       1309.9 KiB  4.04 MiB/s 00:00 [################################################] 100%
 leancrypto-1.4.0-1-x86_64                             1307.9 KiB  4.29 MiB/s 00:00 [################################################] 100%
 e2fsprogs-1.47.2-2-x86_64                             1264.2 KiB  6.24 MiB/s 00:00 [################################################] 100%
 kbd-2.8.0-1-x86_64                                    1258.1 KiB  6.17 MiB/s 00:00 [################################################] 100%
 shadow-4.17.4-1-x86_64                                1244.6 KiB  6.20 MiB/s 00:00 [################################################] 100%
 systemd-libs-257.7-1-x86_64                           1225.9 KiB  4.79 MiB/s 00:00 [################################################] 100%
 curl-8.14.1-1-x86_64                                  1211.7 KiB  5.48 MiB/s 00:00 [################################################] 100%
 archlinux-keyring-20250430.1-1-any                    1208.4 KiB  5.62 MiB/s 00:00 [################################################] 100%
 ncurses-6.5-4-x86_64                                  1158.7 KiB  5.17 MiB/s 00:00 [################################################] 100%
 iproute2-6.15.0-1-x86_64                              1126.6 KiB  3.70 MiB/s 00:00 [################################################] 100%
 tpm2-tss-4.1.3-1-x86_64                                938.8 KiB  2.89 MiB/s 00:00 [################################################] 100%
 pacman-7.0.0.r6.gc685ae6-6-x86_64                      924.5 KiB  4.63 MiB/s 00:00 [################################################] 100%
 procps-ng-4.0.5-3-x86_64                               873.6 KiB  5.02 MiB/s 00:00 [################################################] 100%
 xz-5.8.1-1-x86_64                                      812.1 KiB  4.64 MiB/s 00:00 [################################################] 100%
 cryptsetup-2.8.0-1-x86_64                              799.8 KiB  4.24 MiB/s 00:00 [################################################] 100%
 libxml2-2.14.4-2-x86_64                                794.6 KiB  4.46 MiB/s 00:00 [################################################] 100%
 tar-1.35-2-x86_64                                      777.6 KiB  4.36 MiB/s 00:00 [################################################] 100%
 libcap-2.76-1-x86_64                                   774.9 KiB  4.35 MiB/s 00:00 [################################################] 100%
 libunistring-1.3-1-x86_64                              722.3 KiB  4.44 MiB/s 00:00 [################################################] 100%
 libgcrypt-1.11.1-1-x86_64                              715.2 KiB  3.70 MiB/s 00:00 [################################################] 100%
 libelf-0.193-2-x86_64                                  614.8 KiB  3.51 MiB/s 00:00 [################################################] 100%
 iwd-3.9-1-x86_64                                       598.4 KiB  5.73 MiB/s 00:00 [################################################] 100%
 pam-1.7.1-1-x86_64                                     595.5 KiB  6.32 MiB/s 00:00 [################################################] 100%
 libarchive-3.8.1-1-x86_64                              558.3 KiB  3.47 MiB/s 00:00 [################################################] 100%
 zstd-1.5.7-2-x86_64                                    510.6 KiB  3.37 MiB/s 00:00 [################################################] 100%
 util-linux-libs-2.41.1-1-x86_64                        491.3 KiB  3.16 MiB/s 00:00 [################################################] 100%
 findutils-4.10.0-2-x86_64                              473.4 KiB  3.50 MiB/s 00:00 [################################################] 100%
 nettle-3.10.1-1-x86_64                                 458.5 KiB  6.58 MiB/s 00:00 [################################################] 100%
 libp11-kit-0.25.5-1-x86_64                             456.9 KiB  5.13 MiB/s 00:00 [################################################] 100%
 gmp-6.3.0-2-x86_64                                     442.9 KiB  4.65 MiB/s 00:00 [################################################] 100%
 mpfr-4.2.2-1-x86_64                                    436.8 KiB  3.78 MiB/s 00:00 [################################################] 100%
 file-5.46-4-x86_64                                     432.3 KiB  4.22 MiB/s 00:00 [################################################] 100%
 iptables-1:1.8.11-2-x86_64                             419.0 KiB  6.82 MiB/s 00:00 [################################################] 100%
 libnl-3.11.0-1-x86_64                                  410.3 KiB  5.27 MiB/s 00:00 [################################################] 100%
 audit-4.0.5-1-x86_64                                   405.3 KiB  4.17 MiB/s 00:00 [################################################] 100%
 iana-etc-20250612-1-any                                399.3 KiB  4.38 MiB/s 00:00 [################################################] 100%
 brotli-1.1.0-3-x86_64                                  389.6 KiB  5.51 MiB/s 00:00 [################################################] 100%
 ca-certificates-mozilla-3.113-1-x86_64                 386.4 KiB  4.84 MiB/s 00:00 [################################################] 100%
 tzdata-2025b-1-x86_64                                  347.2 KiB  4.91 MiB/s 00:00 [################################################] 100%
 dbus-1.16.2-1-x86_64                                   346.1 KiB  4.69 MiB/s 00:00 [################################################] 100%
 diffutils-3.12-2-x86_64                                341.9 KiB  4.70 MiB/s 00:00 [################################################] 100%
 readline-8.2.013-2-x86_64                              325.5 KiB  6.11 MiB/s 00:00 [################################################] 100%
 gpgme-2.0.0-1-x86_64                                   317.7 KiB  4.77 MiB/s 00:00 [################################################] 100%
 libpcap-1.10.5-3-x86_64                                288.1 KiB  4.20 MiB/s 00:00 [################################################] 100%
 libldap-2.6.10-1-x86_64                                282.0 KiB  4.17 MiB/s 00:00 [################################################] 100%
 device-mapper-2.03.32-1-x86_64                         280.2 KiB  4.08 MiB/s 00:00 [################################################] 100%
 mkinitcpio-busybox-1.36.1-1-x86_64                     277.5 KiB  4.04 MiB/s 00:00 [################################################] 100%
 libgpg-error-1.55-1-x86_64                             269.1 KiB  3.81 MiB/s 00:00 [################################################] 100%
 libevent-2.1.12-4-x86_64                               267.4 KiB  3.58 MiB/s 00:00 [################################################] 100%
 psmisc-23.7-1-x86_64                                   259.8 KiB  5.90 MiB/s 00:00 [################################################] 100%
 libbpf-1.5.1-1-x86_64                                  254.7 KiB  4.52 MiB/s 00:00 [################################################] 100%
 gdbm-1.25-1-x86_64                                     253.9 KiB  3.59 MiB/s 00:00 [################################################] 100%
 libssh2-1.11.1-1-x86_64                                252.6 KiB  3.68 MiB/s 00:00 [################################################] 100%
 ell-0.78-1-x86_64                                      250.0 KiB  3.81 MiB/s 00:00 [################################################] 100%
 grep-3.12-2-x86_64                                     235.6 KiB  2.99 MiB/s 00:00 [################################################] 100%
 p11-kit-0.25.5-1-x86_64                                223.0 KiB  3.30 MiB/s 00:00 [################################################] 100%
 sed-4.9-3-x86_64                                       210.5 KiB  3.32 MiB/s 00:00 [################################################] 100%
 libsecret-0.21.7-1-x86_64                              188.2 KiB  2.55 MiB/s 00:00 [################################################] 100%
 pinentry-1.3.1-5-x86_64                                184.5 KiB  2.86 MiB/s 00:00 [################################################] 100%
 libtirpc-1.3.6-2-x86_64                                172.8 KiB  2.31 MiB/s 00:00 [################################################] 100%
 lz4-1:1.10.0-2-x86_64                                  156.3 KiB  4.62 MiB/s 00:00 [################################################] 100%
 dbus-broker-37-2-x86_64                                146.8 KiB  3.58 MiB/s 00:00 [################################################] 100%
 libsasl-2.1.28-5-x86_64                                146.6 KiB  3.18 MiB/s 00:00 [################################################] 100%
 pciutils-3.14.0-1-x86_64                               144.7 KiB  3.62 MiB/s 00:00 [################################################] 100%
 libksba-1.6.7-2-x86_64                                 142.2 KiB  4.09 MiB/s 00:00 [################################################] 100%
 libidn2-2.3.7-1-x86_64                                 139.8 KiB  4.27 MiB/s 00:00 [################################################] 100%
 iputils-20250605-1-x86_64                              139.7 KiB  3.59 MiB/s 00:00 [################################################] 100%
 acl-2.3.2-1-x86_64                                     137.8 KiB  3.45 MiB/s 00:00 [################################################] 100%
 gpm-1.20.7.r38.ge82d1a6-6-x86_64                       135.7 KiB  2.95 MiB/s 00:00 [################################################] 100%
 libtasn1-4.20.0-1-x86_64                               133.4 KiB  3.83 MiB/s 00:00 [################################################] 100%
 kmod-34.2-1-x86_64                                     130.3 KiB  2.71 MiB/s 00:00 [################################################] 100%
 gnulib-l10n-20241231-1-any                             124.0 KiB  3.03 MiB/s 00:00 [################################################] 100%
 expat-2.7.1-1-x86_64                                   116.5 KiB  2.47 MiB/s 00:00 [################################################] 100%
 lmdb-0.9.33-1-x86_64                                   116.3 KiB  2.42 MiB/s 00:00 [################################################] 100%
 libassuan-3.0.0-1-x86_64                               112.2 KiB  3.32 MiB/s 00:00 [################################################] 100%
 licenses-20240728-1-any                                105.7 KiB  2.87 MiB/s 00:00 [################################################] 100%
 keyutils-1.6.3-3-x86_64                                102.0 KiB  2.26 MiB/s 00:00 [################################################] 100%
 libnghttp2-1.66.0-1-x86_64                              92.8 KiB  2.45 MiB/s 00:00 [################################################] 100%
 zlib-1:1.3.1-2-x86_64                                   92.3 KiB  2.37 MiB/s 00:00 [################################################] 100%
 libseccomp-2.5.6-1-x86_64                               88.7 KiB  2.71 MiB/s 00:00 [################################################] 100%
 jansson-2.14.1-1-x86_64                                 87.3 KiB  3.05 MiB/s 00:00 [################################################] 100%
 libpsl-0.21.5-2-x86_64                                  86.8 KiB  1886 KiB/s 00:00 [################################################] 100%
 gzip-1.14-2-x86_64                                      86.7 KiB  1844 KiB/s 00:00 [################################################] 100%
 libxcrypt-4.4.38-1-x86_64                               84.6 KiB  1628 KiB/s 00:00 [################################################] 100%
 popt-1.19-2-x86_64                                      76.3 KiB  1251 KiB/s 00:00 [################################################] 100%
 libusb-1.0.29-1-x86_64                                  76.3 KiB  1387 KiB/s 00:00 [################################################] 100%
 libnghttp3-1.10.1-1-x86_64                              73.0 KiB  1622 KiB/s 00:00 [################################################] 100%
 libnftnl-1.2.9-1-x86_64                                 69.9 KiB  1371 KiB/s 00:00 [################################################] 100%
 attr-2.5.2-1-x86_64                                     68.4 KiB  1710 KiB/s 00:00 [################################################] 100%
 mkinitcpio-39.2-3-any                                   64.2 KiB  1528 KiB/s 00:00 [################################################] 100%
 json-c-0.18-2-x86_64                                    58.5 KiB  3.36 MiB/s 00:00 [################################################] 100%
 bzip2-1.0.8-6-x86_64                                    58.4 KiB  2.48 MiB/s 00:00 [################################################] 100%
 libsysprof-capture-48.0-5-x86_64                        49.3 KiB  1898 KiB/s 00:00 [################################################] 100%
 libnetfilter_conntrack-1.0.9-2-x86_64                   47.6 KiB  1981 KiB/s 00:00 [################################################] 100%
 libffi-3.5.0-1-x86_64                                   46.7 KiB  1229 KiB/s 00:00 [################################################] 100%
 libcap-ng-0.8.5-3-x86_64                                41.6 KiB  1301 KiB/s 00:00 [################################################] 100%
 linux-firmware-whence-20250613.12fe085f-9-any           39.8 KiB  2.29 MiB/s 00:00 [################################################] 100%
 npth-1.8-1-x86_64                                       28.2 KiB   882 KiB/s 00:00 [################################################] 100%
 libnsl-2.0.1-1-x86_64                                   21.7 KiB   678 KiB/s 00:00 [################################################] 100%
 libverto-0.3.2-5-x86_64                                 18.3 KiB   963 KiB/s 00:00 [################################################] 100%
 libnfnetlink-1.0.2-2-x86_64                             17.0 KiB   851 KiB/s 00:00 [################################################] 100%
 filesystem-2025.05.03-1-any                             14.5 KiB   355 KiB/s 00:00 [################################################] 100%
 libmnl-1.0.5-2-x86_64                                   11.2 KiB   273 KiB/s 00:00 [################################################] 100%
 ca-certificates-utils-20240618-1-any                    10.8 KiB   432 KiB/s 00:00 [################################################] 100%
 pacman-mirrorlist-20250522-1-any                         8.1 KiB   270 KiB/s 00:00 [################################################] 100%
 systemd-sysvcompat-257.7-1-x86_64                        6.1 KiB   204 KiB/s 00:00 [################################################] 100%
 pambase-20230918-2-any                                   3.0 KiB  92.4 KiB/s 00:00 [################################################] 100%
 dbus-broker-units-37-2-x86_64                            2.4 KiB   105 KiB/s 00:00 [################################################] 100%
 linux-firmware-20250613.12fe085f-9-any                   2.4 KiB   104 KiB/s 00:00 [################################################] 100%
 base-3-2-any                                             2.3 KiB  76.9 KiB/s 00:00 [################################################] 100%
 dbus-units-37-2-x86_64                                   2.2 KiB  72.7 KiB/s 00:00 [################################################] 100%
 ca-certificates-20240618-1-any                           2.1 KiB   149 KiB/s 00:00 [################################################] 100%
 Total (143/143)                                        635.8 MiB  18.4 MiB/s 00:35 [################################################] 100%
(143/143) checking keys in keyring                                                  [################################################] 100%
(143/143) checking package integrity                                                [################################################] 100%
(143/143) loading package files                                                     [################################################] 100%
(143/143) checking for file conflicts                                               [################################################] 100%
(143/143) checking available disk space                                             [################################################] 100%
:: Processing package changes...
(  1/143) installing iana-etc                                                       [################################################] 100%
(  2/143) installing filesystem                                                     [################################################] 100%
(  3/143) installing linux-api-headers                                              [################################################] 100%
(  4/143) installing tzdata                                                         [################################################] 100%
Optional dependencies for tzdata
    bash: for tzselect [pending]
    glibc: for zdump, zic [pending]
(  5/143) installing glibc                                                          [################################################] 100%
Optional dependencies for glibc
    gd: for memusagestat
    perl: for mtrace
(  6/143) installing gcc-libs                                                       [################################################] 100%
(  7/143) installing ncurses                                                        [################################################] 100%
Optional dependencies for ncurses
    bash: for ncursesw6-config [pending]
(  8/143) installing readline                                                       [################################################] 100%
(  9/143) installing bash                                                           [################################################] 100%
Optional dependencies for bash
    bash-completion: for tab completion
( 10/143) installing acl                                                            [################################################] 100%
( 11/143) installing attr                                                           [################################################] 100%
( 12/143) installing gmp                                                            [################################################] 100%
( 13/143) installing zlib                                                           [################################################] 100%
( 14/143) installing sqlite                                                         [################################################] 100%
( 15/143) installing util-linux-libs                                                [################################################] 100%
Optional dependencies for util-linux-libs
    python: python bindings to libmount
( 16/143) installing e2fsprogs                                                      [################################################] 100%
Optional dependencies for e2fsprogs
    lvm2: for e2scrub
    util-linux: for e2scrub [pending]
    smtp-forwarder: for e2scrub_fail script
( 17/143) installing keyutils                                                       [################################################] 100%
( 18/143) installing gdbm                                                           [################################################] 100%
( 19/143) installing openssl                                                        [################################################] 100%
Optional dependencies for openssl
    ca-certificates [pending]
    perl
( 20/143) installing libsasl                                                        [################################################] 100%
( 21/143) installing libldap                                                        [################################################] 100%
( 22/143) installing libevent                                                       [################################################] 100%
Optional dependencies for libevent
    python: event_rpcgen.py
( 23/143) installing libverto                                                       [################################################] 100%
( 24/143) installing lmdb                                                           [################################################] 100%
( 25/143) installing krb5                                                           [################################################] 100%
( 26/143) installing libcap-ng                                                      [################################################] 100%
( 27/143) installing audit                                                          [################################################] 100%
Optional dependencies for audit
    libldap: for audispd-zos-remote [installed]
    sh: for augenrules [installed]
( 28/143) installing libxcrypt                                                      [################################################] 100%
( 29/143) installing libtirpc                                                       [################################################] 100%
( 30/143) installing libnsl                                                         [################################################] 100%
( 31/143) installing pambase                                                        [################################################] 100%
( 32/143) installing libgpg-error                                                   [################################################] 100%
( 33/143) installing libgcrypt                                                      [################################################] 100%
( 34/143) installing lz4                                                            [################################################] 100%
( 35/143) installing xz                                                             [################################################] 100%
( 36/143) installing zstd                                                           [################################################] 100%
( 37/143) installing systemd-libs                                                   [################################################] 100%
( 38/143) installing pam                                                            [################################################] 100%
( 39/143) installing libcap                                                         [################################################] 100%
( 40/143) installing coreutils                                                      [################################################] 100%
( 41/143) installing bzip2                                                          [################################################] 100%
( 42/143) installing libseccomp                                                     [################################################] 100%
( 43/143) installing file                                                           [################################################] 100%
( 44/143) installing findutils                                                      [################################################] 100%
( 45/143) installing mpfr                                                           [################################################] 100%
( 46/143) installing gawk                                                           [################################################] 100%
( 47/143) installing pcre2                                                          [################################################] 100%
Optional dependencies for pcre2
    sh: for pcre2-config [installed]
( 48/143) installing grep                                                           [################################################] 100%
( 49/143) installing procps-ng                                                      [################################################] 100%
( 50/143) installing sed                                                            [################################################] 100%
( 51/143) installing tar                                                            [################################################] 100%
( 52/143) installing gnulib-l10n                                                    [################################################] 100%
( 53/143) installing libunistring                                                   [################################################] 100%
( 54/143) installing icu                                                            [################################################] 100%
( 55/143) installing libxml2                                                        [################################################] 100%
Optional dependencies for libxml2
    python: Python bindings
( 56/143) installing gettext                                                        [################################################] 100%
Optional dependencies for gettext
    git: for autopoint infrastructure updates
    appstream: for appstream support
( 57/143) installing hwdata                                                         [################################################] 100%
( 58/143) installing kmod                                                           [################################################] 100%
( 59/143) installing pciutils                                                       [################################################] 100%
Optional dependencies for pciutils
    which: for update-pciids
    grep: for update-pciids [installed]
    curl: for update-pciids [pending]
( 60/143) installing psmisc                                                         [################################################] 100%
( 61/143) installing shadow                                                         [################################################] 100%
( 62/143) installing util-linux                                                     [################################################] 100%
Optional dependencies for util-linux
    words: default dictionary for look
( 63/143) installing gzip                                                           [################################################] 100%
Optional dependencies for gzip
    less: zless support
    util-linux: zmore support [installed]
    diffutils: zdiff/zcmp support [pending]
( 64/143) installing licenses                                                       [################################################] 100%
( 65/143) installing libtasn1                                                       [################################################] 100%
( 66/143) installing libffi                                                         [################################################] 100%
( 67/143) installing libp11-kit                                                     [################################################] 100%
( 68/143) installing p11-kit                                                        [################################################] 100%
( 69/143) installing ca-certificates-utils                                          [################################################] 100%
( 70/143) installing ca-certificates-mozilla                                        [################################################] 100%
( 71/143) installing ca-certificates                                                [################################################] 100%
( 72/143) installing brotli                                                         [################################################] 100%
( 73/143) installing libidn2                                                        [################################################] 100%
( 74/143) installing libnghttp2                                                     [################################################] 100%
( 75/143) installing libnghttp3                                                     [################################################] 100%
( 76/143) installing libpsl                                                         [################################################] 100%
( 77/143) installing libssh2                                                        [################################################] 100%
( 78/143) installing curl                                                           [################################################] 100%
( 79/143) installing nettle                                                         [################################################] 100%
( 80/143) installing leancrypto                                                     [################################################] 100%
( 81/143) installing gnutls                                                         [################################################] 100%
Optional dependencies for gnutls
    tpm2-tss: support for TPM2 wrapped keys [pending]
( 82/143) installing libksba                                                        [################################################] 100%
( 83/143) installing libusb                                                         [################################################] 100%
( 84/143) installing libassuan                                                      [################################################] 100%
( 85/143) installing libsysprof-capture                                             [################################################] 100%
( 86/143) installing glib2                                                          [################################################] 100%
Optional dependencies for glib2
    dconf: GSettings storage backend
    glib2-devel: development tools
    gvfs: most gio functionality
( 87/143) installing json-c                                                         [################################################] 100%
( 88/143) installing tpm2-tss                                                       [################################################] 100%
( 89/143) installing libsecret                                                      [################################################] 100%
Optional dependencies for libsecret
    org.freedesktop.secrets: secret storage backend
( 90/143) installing pinentry                                                       [################################################] 100%
Optional dependencies for pinentry
    gcr: GNOME backend
    gtk3: GTK backend
    qt5-x11extras: Qt5 backend
    kwayland5: Qt5 backend
    kguiaddons: Qt6 backend
    kwindowsystem: Qt6 backend
( 91/143) installing npth                                                           [################################################] 100%
( 92/143) installing gnupg                                                          [################################################] 100%
Optional dependencies for gnupg
    pcsclite: for using scdaemon not with the gnupg internal card driver
( 93/143) installing gpgme                                                          [################################################] 100%
( 94/143) installing libarchive                                                     [################################################] 100%
( 95/143) installing pacman-mirrorlist                                              [################################################] 100%
( 96/143) installing device-mapper                                                  [################################################] 100%
( 97/143) installing popt                                                           [################################################] 100%
( 98/143) installing cryptsetup                                                     [################################################] 100%
( 99/143) installing expat                                                          [################################################] 100%
(100/143) installing dbus                                                           [################################################] 100%
(101/143) installing dbus-broker                                                    [################################################] 100%
(102/143) installing dbus-broker-units                                              [################################################] 100%
(103/143) installing dbus-units                                                     [################################################] 100%
(104/143) installing kbd                                                            [################################################] 100%
(105/143) installing libelf                                                         [################################################] 100%
(106/143) installing systemd                                                        [################################################] 100%
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
(107/143) installing pacman                                                         [################################################] 100%
Optional dependencies for pacman
    base-devel: required to use makepkg
    perl-locale-gettext: translation support in makepkg-template
(108/143) installing archlinux-keyring                                              [################################################] 100%
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
  -> Disabled 46 keys.
==> Updating trust database...
gpg: Note: third-party key signatures using the SHA1 algorithm are rejected
gpg: (use option "--allow-weak-key-signatures" to override)
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   5  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: depth: 1  valid:   5  signed: 102  trust: 0-, 0q, 0n, 5m, 0f, 0u
gpg: depth: 2  valid:  78  signed:  20  trust: 78-, 0q, 0n, 0m, 0f, 0u
gpg: next trustdb check due at 2025-07-01
(109/143) installing systemd-sysvcompat                                             [################################################] 100%
(110/143) installing iputils                                                        [################################################] 100%
(111/143) installing libmnl                                                         [################################################] 100%
(112/143) installing libnftnl                                                       [################################################] 100%
(113/143) installing libnl                                                          [################################################] 100%
(114/143) installing libpcap                                                        [################################################] 100%
(115/143) installing libnfnetlink                                                   [################################################] 100%
(116/143) installing libnetfilter_conntrack                                         [################################################] 100%
(117/143) installing iptables                                                       [################################################] 100%
(118/143) installing libbpf                                                         [################################################] 100%
(119/143) installing iproute2                                                       [################################################] 100%
Optional dependencies for iproute2
    db5.3: userspace arp daemon
    linux-atm: ATM support
    python: for routel
(120/143) installing base                                                           [################################################] 100%
Optional dependencies for base
    linux: bare metal support [pending]
(121/143) installing mkinitcpio-busybox                                             [################################################] 100%
(122/143) installing jansson                                                        [################################################] 100%
(123/143) installing binutils                                                       [################################################] 100%
Optional dependencies for binutils
    debuginfod: for debuginfod server/client functionality
(124/143) installing diffutils                                                      [################################################] 100%
(125/143) installing mkinitcpio                                                     [################################################] 100%
Optional dependencies for mkinitcpio
    xz: Use lzma or xz compression for the initramfs image [installed]
    bzip2: Use bzip2 compression for the initramfs image [installed]
    lzop: Use lzo compression for the initramfs image
    lz4: Use lz4 compression for the initramfs image [installed]
    mkinitcpio-nfs-utils: Support for root filesystem on NFS
    systemd-ukify: alternative UKI generator
(126/143) installing linux                                                          [################################################] 100%
Optional dependencies for linux
    linux-firmware: firmware images needed for some devices [pending]
    scx-scheds: to use sched-ext schedulers
    wireless-regdb: to set the correct wireless channels of your country
(127/143) installing linux-firmware-whence                                          [################################################] 100%
(128/143) installing linux-firmware-amdgpu                                          [################################################] 100%
(129/143) installing linux-firmware-atheros                                         [################################################] 100%
(130/143) installing linux-firmware-broadcom                                        [################################################] 100%
(131/143) installing linux-firmware-cirrus                                          [################################################] 100%
(132/143) installing linux-firmware-intel                                           [################################################] 100%
(133/143) installing linux-firmware-mediatek                                        [################################################] 100%
(134/143) installing linux-firmware-nvidia                                          [################################################] 100%
(135/143) installing linux-firmware-other                                           [################################################] 100%
(136/143) installing linux-firmware-radeon                                          [################################################] 100%
(137/143) installing linux-firmware-realtek                                         [################################################] 100%
(138/143) installing linux-firmware                                                 [################################################] 100%
Optional dependencies for linux-firmware
    linux-firmware-liquidio: Firmware for Cavium LiquidIO server adapters
    linux-firmware-marvell: Firmware for Marvell devices
    linux-firmware-mellanox: Firmware for Mellanox Spectrum switches
    linux-firmware-nfp: Firmware for Netronome Flow Processors
    linux-firmware-qcom: Firmware for Qualcomm SoCs
    linux-firmware-qlogic: Firmware for QLogic devices
(139/143) installing ell                                                            [################################################] 100%
(140/143) installing iwd                                                            [################################################] 100%
Optional dependencies for iwd
    qrencode: for displaying QR code after DPP is started
(141/143) installing vim-runtime                                                    [################################################] 100%
Optional dependencies for vim-runtime
    sh: support for some tools and macros [installed]
    python: demoserver example tool
    gawk: mve tools upport [installed]
(142/143) installing gpm                                                            [################################################] 100%
(143/143) installing vim                                                            [################################################] 100%
Optional dependencies for vim
    python: Python language support
    ruby: Ruby language support
    lua: Lua language support
    perl: Perl language support
    tcl: Tcl language support
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
==> Starting build: '6.15.3-arch1-1'
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
==> Starting build: '6.15.3-arch1-1'
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
==> WARNING: Possibly missing firmware for module: 'aic94xx'
==> WARNING: Possibly missing firmware for module: 'qed'
==> WARNING: Possibly missing firmware for module: 'bfa'
==> WARNING: Possibly missing firmware for module: 'qla2xxx'
==> WARNING: Possibly missing firmware for module: 'qla1280'
==> WARNING: Possibly missing firmware for module: 'wd719x'
  -> Running build hook: [filesystems]
  -> Running build hook: [fsck]
==> Generating module dependencies
==> Creating zstd-compressed initcpio image: '/boot/initramfs-linux-fallback.img'
  -> Early uncompressed CPIO image generation successful
==> Initcpio image generation successful
(13/13) Reloading system bus configuration...
  Skipped: Running in chroot.
pacstrap -K /mnt base linux linux-firmware iwd vim  23.98s user 17.64s system 58% cpu 1:11.40 total
```

I'm going to keep this in for the time being for later review, however, this is not required by any measure ;)

## Configure the sytem
Lets create the fstab using `genfstab` tool

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
System Time: 1750941382.787907
Trying to open: /dev/rtc0
Using the rtc interface to the clock.
Assuming hardware clock is kept in UTC time.
RTC type: 'rtc_cmos'
Using delay: 0.500000 seconds
missed it - 1750941382.791176 is too far past 1750941382.500000 (0.291176 > 0.001000)
1750941383.500000 is close enough to 1750941383.500000 (0.000000 < 0.002000)
Set RTC to 1750941383 (1750941382 + 1; refsystime = 1750941382.000000)
Setting Hardware Clock to 12:36:23 = 1750941383 seconds since 1969
ioctl(RTC_SET_TIME) was successful.
Not adjusting drift factor because the --update-drift option was not used.
New /etc/adjtime data:
0.000000 1750941382 0.000000
1750941382
UTC
```

### Locale







