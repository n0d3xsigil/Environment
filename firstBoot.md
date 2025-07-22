Once arch is built, you'll need to log in and get a few things up and running...

## Contents
- [Network connectivity](#network-connectivity)
- [Secure boot](#secure-boot)
- [Create user](#create-user)
- [Enable Sudo](#enable-sudo)
- [Disable root](#disable-root)
- [Configure firewall](#configure-firewall)
- [nvidia hell](#nvidia-hell)
- [LightDM](#lightdm)
- [i3 WM](#i3-wm)

  
## Network connectivity

First we need to enable `iwd` to allow us to configure and control it. 

We need to allow `iwd` to handle the network its self, such as DHCP.



```shell
vim /etc/iwd/main.conf; cat /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true
```

Next we need to enable DNS

```shell
systemctl enable --now systemd-resolved
```

We have `iwd` to configure wireless. Enable it and get it running before we connect

```shell
systemctl enable --now iwd
Created symlink '/etc/systemd/system/multi-user.target.wants/iwd.service' → '/user/lib/systemd/system/iwd.service'
```

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

Let's enable `sshd` 

```shell
[root@archibold ~]# systemctl enable --now sshd
Created symlink '/etc/systemd/system/multi-user.target.wants/sshd.service' → '/usr/lib/systemd/system/sshd.service'.
```

Now we can remote into the system.



## Secure boot
Not that kind of secureboot

```shell
chmod 0700 /boot
chmod 0700 /boot/loader
chmod 0700 /boot/loader/entries
chmod 0600 /boot/loader/random-seed
```


## Create user

We should never ever run as `root` only bad things can happen. So I like to create strong password and document the password (somewhere) for root and then use the new user account

```shell
[root@archibold ~]# useradd -m archibold
```


Of course we want to change the password of the new user

```shell
[root@archibold ~]# passwd archibold
New password:           notMypassword
Retype new password:    notMypassword
passwd: password updated successfully
```


## Enable Sudo

Sudo alows us to perform user substitution or to escilate our privileges, we installed it under `pacstrap`. Let's configure it

We need to allow are new user access to run sudo

```shell
[root@archibold ~]# EDITOR=vim visudo
```


Add `archibold ALL=(ALL:ALL) ALL`.


We also want to add the following lines before `## Read drop-in files from /etc/sudoers.d`

```text
Defaults timestamp_timeout=0
Defaults passwd_tries=2
Defaults env_reset
```


ensure only `root` can modify `/etc/sudoers`

```shell
[archibold@archibold ~]$ sudo -s
[sudo] password for archibold:   P@$$w0rd!
[root@archibold archibold]# chmod 440 /etc/sudoers
[root@archibold archibold]# chown root:root /etc/sudoers
```


This makes it harder to do naughty things ;)

We can now logout and log back in with the new user.


## Disable root

First we need to change the `root` password by using `passwd`. Since I logged in with the new user I will use `sudo -s` to change the password

```shell
[archibold@archibold ~]$ sudo -s
[sudo] password for archibold:  someLongPassword
[root@archibold archibold]# passwd
New password:           XQQ8Si8Fa7keig
Retype new password:    XQQ8Si8Fa7keig
passwd: password updated successfully
```

Clearly `XQQ8Si8Fa7keig` is an example and not a real password.


Next we want to lock root so it can't be accessed or bruteforced.

```shell
[archibold@archibold ~]$ sudo passwd -l root
[sudo] password for archibold:    SomeRandomPassword
passwd: password changed.
```


## Configure firewall

We will use `ufw` since we installed this back in pacstrap times

For the time being only allow `ssh`

```shell
[archibold@archibold ~]$ sudo ufw allow ssh
[sudo] password for archibold:    anotherRandomPassword
Rules updated
Rules updated (v6)
```


Setup default deny rules for incomming traffic

```shell
[archibold@archibold ~]$ sudo ufw default deny incoming
[sudo] password for archibold:
Default incoming policy changed to 'deny'
(be sure to update your rules accordingly)
```


Set up default allow rules for outgoing traffic

```shell
[archibold@archibold ~]$ sudo ufw default allow outgoing
[sudo] password for archibold:   whoKnowsReally
Default outgoing policy changed to 'allow'
(be sure to update your rules accordingly)
```


Next enable and start ufw

```shell
[archibold@archibold ~]$ sudo ufw enable
[sudo] password for archibold:    thisIsVeryBoring
Command may disrupt existing ssh connections. Proceed with operation (y|n)? y
Firewall is active and enabled on system startup
```


Now enable the service

```shell
[archibold@archibold ~]$ sudo systemctl enable --now ufw
[sudo] password for archibold:    abc123
Created symlink '/etc/systemd/system/multi-user.target.wants/ufw.service' → '/usr/lib/systemd/system/ufw.service'.
```


I want to enable logging

```shell
[archibold@archibold ~]$ sudo ufw logging on
[sudo] password for archibold:   321bca
Logging enabled
```


Finally I want to disable `remote-fs` as I don't use it (yet)

```shell
[archibold@archibold ~]$ sudo systemctl disable --now remote-fs.target
[sudo] password for archibold:    letmein
Removed '/etc/systemd/system/multi-user.target.wants/remote-fs.target'.
```


## nVidia hell

I always have issues getting nvidia/intel graphics to work well together.

What is showing up

```shell
[archibold@archibold ~]$ lspci | grep -i vga
0000:00:02.0 VGA compatible controller: Intel Corporation TigerLake-H GT1 [UHD Graphics] (rev 01)
0000:01:00.0 VGA compatible controller: NVIDIA Corporation GA107GLM [RTX A2000 Mobile] (rev a1)
```

lets get the `nvidia` and `intel` drivers

before we do that, we need to enable multi lib

```shell
[archibold@archibold ~]$ sudo vim /etc/pacman.conf
```

uncomment the following lines

```text
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Issue a package refresh to download the `multilib` database

```shell
[archibold@archibold ~]$ sudo pacman -Syy
[sudo] password for archibold:   AnotherPassword
:: Synchronising package databases...
core                                                                                    120.2 KiB   884 KiB/s 00:00 [####################] 100%
extra                                                                                     7.8 MiB  11.0 MiB/s 00:01 [####################] 100%
multilib                                                                                131.6 KiB   989 KiB/s 00:00 [####################] 100%
archibold@archibold ~]$
```



Next, let's bloat the system

```shell
[archibold@archibold ~]$ sudo pacman -S nvidia nvidia-utils lib32-nvidia-utils mesa lib32-mesa xf86-video-intel vulkan-intel vulkan-icd-loader mesa-demos mesa-utils
[sudo] password for archibold:
resolving dependencies...
looking for conflicting packages...
warning: dependency cycle detected:
warning: libglvnd will be installed before its nvidia-utils dependency
warning: dependency cycle detected:
warning: mesa will be installed before its libglvnd dependency
warning: dependency cycle detected:
warning: lib32-libglvnd will be installed before its lib32-nvidia-utils dependency
warning: dependency cycle detected:
warning: lib32-mesa will be installed before its lib32-libglvnd dependency
warning: dependency cycle detected:
warning: lib32-keyutils will be installed before its lib32-krb5 dependency
warning: dependency cycle detected:
warning: harfbuzz will be installed before its freetype2 dependency

Packages (100) cairo-1.18.4-1  default-cursors-3-1  egl-gbm-1.1.2.1-1  egl-wayland-4:1.1.19-1  egl-x11-1.0.2-1  eglexternalplatform-1.2.1-1  fontconfig-2:2.17.1-1  freeglut-3.6.0-2
               freetype2-2.13.3-3  fribidi-1.0.16-2  glu-9.0.3-2  graphite-1:1.3.14-5  harfbuzz-11.2.1-1  lib32-brotli-1.1.0-1  lib32-bzip2-1.0.8-4  lib32-curl-8.15.0-1
               lib32-e2fsprogs-1.47.3-1  lib32-expat-2.7.1-1  lib32-gcc-libs-15.1.1+r7+gf36ec88aa85a-1  lib32-glibc-2.41+r48+g5cb575ca9a3d-1  lib32-icu-76.1-1  lib32-json-c-0.18-2
               lib32-keyutils-1.6.3-2  lib32-krb5-1.21.3-1  lib32-libdrm-2.4.125-1  lib32-libelf-0.193-1  lib32-libffi-3.5.1-1  lib32-libglvnd-1.7.0-1  lib32-libidn2-2.3.7-1
               lib32-libldap-2.6.10-1  lib32-libnghttp2-1.66.0-1  lib32-libnghttp3-1.10.1-1  lib32-libpciaccess-0.18.1-1  lib32-libpsl-0.21.5-1  lib32-libssh2-1.11.1-1  lib32-libunistring-1.3-1
               lib32-libx11-1.8.12-1  lib32-libxau-1.0.11-2  lib32-libxcb-1.17.0-1  lib32-libxcrypt-4.4.38-1  lib32-libxdmcp-1.1.5-1  lib32-libxext-1.3.6-1  lib32-libxml2-2.14.5-1
               lib32-libxshmfence-1.3.3-1  lib32-libxxf86vm-1.1.5-2  lib32-llvm-libs-1:20.1.8-1  lib32-lm_sensors-1:3.6.2-2  lib32-ncurses-6.5-2  lib32-openssl-1:3.5.1-1
               lib32-spirv-tools-1:1.4.321.0-1  lib32-wayland-1.23.1-1  lib32-xz-5.8.1-1  lib32-zlib-1.3.1-2  lib32-zstd-1.5.7-2  libdatrie-0.2.13-4  libdecor-0.2.3-1  libdrm-2.4.125-1
               libglvnd-1.7.0-3  libpciaccess-0.18.1-2  libpng-1.6.50-1  libthai-0.1.29-3  libx11-1.8.12-1  libxau-1.0.12-1  libxcb-1.17.0-1  libxdamage-1.1.6-2  libxdmcp-1.1.5-1
               libxext-1.3.6-1  libxfixes-6.0.1-2  libxft-2.3.9-1  libxi-1.8.2-1  libxkbcommon-1.10.0-1  libxkbcommon-x11-1.10.0-1  libxrandr-1.5.4-1  libxrender-0.9.12-1  libxshmfence-1.3.3-1
               libxv-1.0.13-1  libxvmc-1.0.14-1  libxxf86vm-1.1.6-1  llvm-libs-20.1.8-1  lm_sensors-1:3.6.2-1  lzo-2.10-5  pango-1:1.56.4-1  pixman-0.46.4-1  spirv-tools-1:1.4.321.0-1
               wayland-1.23.1-2  xcb-proto-1.17.0-3  xcb-util-0.4.1-2  xcb-util-keysyms-0.4.1-5  xkeyboard-config-2.45-1  xorgproto-2024.1-2  lib32-mesa-1:25.1.6-1
               lib32-nvidia-utils-575.64.03-1  mesa-1:25.1.6-1  mesa-demos-9.0.0-7  mesa-utils-9.0.0-7  nvidia-575.64.03-4  nvidia-utils-575.64.03-1  vulkan-icd-loader-1.4.321.0-1
               vulkan-intel-1:25.1.6-1  xf86-video-intel-1:2.99.917+939+g4a64400e-1

Total Download Size:    588.13 MiB
Total Installed Size:  1946.85 MiB

:: Proceed with installation? [Y/n] Y
:: Retrieving packages...
 lib32-spirv-tools-1:1.4.321.0-1-x86_64                                                 1549.1 KiB  1065 KiB/s 00:01 [######################################################################] 100% lib32-openssl-1:3.5.1-1-x86_64                                                         2013.8 KiB  1369 KiB/s 00:01 [######################################################################] 100% spirv-tools-1:1.4.321.0-1-x86_64                                                       1809.4 KiB   984 KiB/s 00:02 [######################################################################] 100% libx11-1.8.12-1-x86_64                                                                    2.0 MiB   838 KiB/s 00:02 [######################################################################] 100% vulkan-intel-1:25.1.6-1-x86_64                                                            4.3 MiB  1734 KiB/s 00:03 [######################################################################] 100% harfbuzz-11.2.1-1-x86_64                                                               1121.2 KiB   932 KiB/s 00:01 [######################################################################] 100% lib32-glibc-2.41+r48+g5cb575ca9a3d-1-x86_64                                               3.4 MiB  1272 KiB/s 00:03 [######################################################################] 100% mesa-demos-9.0.0-7-x86_64                                                                 2.8 MiB   955 KiB/s 00:03 [######################################################################] 100% libxcb-1.17.0-1-x86_64                                                                  996.0 KiB   520 KiB/s 00:02 [######################################################################] 100% xkeyboard-config-2.45-1-any                                                             867.2 KiB   341 KiB/s 00:03 [######################################################################] 100% cairo-1.18.4-1-x86_64                                                                   620.1 KiB   279 KiB/s 00:02 [######################################################################] 100% lib32-libx11-1.8.12-1-x86_64                                                            618.9 KiB   281 KiB/s 00:02 [######################################################################] 100% xf86-video-intel-1:2.99.917+939+g4a64400e-1-x86_64                                      726.0 KiB   287 KiB/s 00:03 [######################################################################] 100% lib32-krb5-1.21.3-1-x86_64                                                              775.4 KiB   288 KiB/s 00:03 [######################################################################] 100% lib32-libelf-0.193-1-x86_64                                                             586.4 KiB   290 KiB/s 00:02 [######################################################################] 100% lib32-libunistring-1.3-1-x86_64                                                         557.7 KiB   335 KiB/s 00:02 [######################################################################] 100% freetype2-2.13.3-3-x86_64                                                               525.9 KiB   645 KiB/s 00:01 [######################################################################] 100% mesa-1:25.1.6-1-x86_64                                                                   10.2 MiB  1727 KiB/s 00:06 [######################################################################] 100% lib32-libxml2-2.14.5-1-x86_64                                                           506.4 KiB   473 KiB/s 00:01 [######################################################################] 100% lib32-curl-8.15.0-1-x86_64                                                              375.8 KiB   236 KiB/s 00:02 [######################################################################] 100% fontconfig-2:2.17.1-1-x86_64                                                            374.4 KiB   231 KiB/s 00:02 [######################################################################] 100% pango-1:1.56.4-1-x86_64                                                                 422.4 KiB   239 KiB/s 00:02 [######################################################################] 100% libdrm-2.4.125-1-x86_64                                                                 347.7 KiB   235 KiB/s 00:01 [######################################################################] 100% lib32-brotli-1.1.0-1-x86_64                                                             340.5 KiB   224 KiB/s 00:02 [######################################################################] 100% lib32-mesa-1:25.1.6-1-x86_64                                                             10.3 MiB  1418 KiB/s 00:07 [######################################################################] 100% libglvnd-1.7.0-3-x86_64                                                                 326.2 KiB   332 KiB/s 00:01 [######################################################################] 100% lib32-zstd-1.5.7-2-x86_64                                                               324.4 KiB   321 KiB/s 00:01 [######################################################################] 100% pixman-0.46.4-1-x86_64                                                                  284.6 KiB   533 KiB/s 00:01 [######################################################################] 100% libthai-0.1.29-3-x86_64                                                                 275.3 KiB   631 KiB/s 00:00 [######################################################################] 100% libpng-1.6.50-1-x86_64                                                                  253.2 KiB   364 KiB/s 00:01 [######################################################################] 100% libxkbcommon-1.10.0-1-x86_64                                                            242.9 KiB   276 KiB/s 00:01 [######################################################################] 100% xorgproto-2024.1-2-any                                                                  241.2 KiB   258 KiB/s 00:01 [######################################################################] 100% lib32-e2fsprogs-1.47.3-1-x86_64                                                         223.6 KiB   235 KiB/s 00:01 [######################################################################] 100% lib32-libldap-2.6.10-1-x86_64                                                           159.9 KiB   210 KiB/s 00:01 [######################################################################] 100% lib32-ncurses-6.5-2-x86_64                                                              219.6 KiB   236 KiB/s 00:01 [######################################################################] 100% lib32-libglvnd-1.7.0-1-x86_64                                                           202.7 KiB   232 KiB/s 00:01 [######################################################################] 100% lib32-libxcb-1.17.0-1-x86_64                                                            196.1 KiB   224 KiB/s 00:01 [######################################################################] 100% glu-9.0.3-2-x86_64                                                                      152.2 KiB   456 KiB/s 00:00 [######################################################################] 100% lib32-icu-76.1-1-x86_64                                                                  10.6 MiB  1242 KiB/s 00:09 [######################################################################] 100% mesa-utils-9.0.0-7-x86_64                                                               151.6 KiB   564 KiB/s 00:00 [######################################################################] 100% libxi-1.8.2-1-x86_64                                                                    150.5 KiB   452 KiB/s 00:00 [######################################################################] 100% vulkan-icd-loader-1.4.321.0-1-x86_64                                                    144.6 KiB   393 KiB/s 00:00 [######################################################################] 100% wayland-1.23.1-2-x86_64                                                                 140.1 KiB   354 KiB/s 00:00 [######################################################################] 100% lib32-libdrm-2.4.125-1-x86_64                                                           139.0 KiB   317 KiB/s 00:00 [######################################################################] 100% lm_sensors-1:3.6.2-1-x86_64                                                             133.6 KiB   326 KiB/s 00:00 [######################################################################] 100% xcb-proto-1.17.0-3-any                                                                  128.5 KiB   299 KiB/s 00:00 [######################################################################] 100% lib32-libssh2-1.11.1-1-x86_64                                                           114.9 KiB   255 KiB/s 00:00 [######################################################################] 100% libdatrie-0.2.13-4-x86_64                                                               114.2 KiB   277 KiB/s 00:00 [######################################################################] 100% libxext-1.3.6-1-x86_64                                                                  106.0 KiB   375 KiB/s 00:00 [######################################################################] 100% lib32-xz-5.8.1-1-x86_64                                                                 104.2 KiB   367 KiB/s 00:00 [######################################################################] 100% freeglut-3.6.0-2-x86_64                                                                 104.1 KiB   320 KiB/s 00:00 [######################################################################] 100% lzo-2.10-5-x86_64                                                                        87.8 KiB   283 KiB/s 00:00 [######################################################################] 100% graphite-1:1.3.14-5-x86_64                                                               83.7 KiB   266 KiB/s 00:00 [######################################################################] 100% fribidi-1.0.16-2-x86_64                                                                  71.1 KiB   241 KiB/s 00:00 [######################################################################] 100% lib32-expat-2.7.1-1-x86_64                                                               67.9 KiB   229 KiB/s 00:00 [######################################################################] 100% lib32-libxcrypt-4.4.38-1-x86_64                                                          66.7 KiB   225 KiB/s 00:00 [######################################################################] 100% lib32-libnghttp3-1.10.1-1-x86_64                                                         64.2 KiB   216 KiB/s 00:00 [######################################################################] 100% lib32-libnghttp2-1.66.0-1-x86_64                                                         64.1 KiB   290 KiB/s 00:00 [######################################################################] 100% libxft-2.3.9-1-x86_64                                                                    60.4 KiB   959 KiB/s 00:00 [######################################################################] 100% lib32-libpsl-0.21.5-1-x86_64                                                             55.5 KiB  1028 KiB/s 00:00 [######################################################################] 100% lib32-libidn2-2.3.7-1-x86_64                                                             54.3 KiB   724 KiB/s 00:00 [######################################################################] 100% lib32-wayland-1.23.1-1-x86_64                                                            53.3 KiB   561 KiB/s 00:00 [######################################################################] 100% lib32-zlib-1.3.1-2-x86_64                                                                47.2 KiB   524 KiB/s 00:00 [######################################################################] 100% libdecor-0.2.3-1-x86_64                                                                  45.3 KiB   420 KiB/s 00:00 [######################################################################] 100% egl-x11-1.0.2-1-x86_64                                                                   37.8 KiB   313 KiB/s 00:00 [######################################################################] 100% egl-wayland-4:1.1.19-1-x86_64                                                            36.8 KiB   338 KiB/s 00:00 [######################################################################] 100% lib32-json-c-0.18-2-x86_64                                                               35.6 KiB   280 KiB/s 00:00 [######################################################################] 100% libxv-1.0.13-1-x86_64                                                                    34.9 KiB   353 KiB/s 00:00 [######################################################################] 100% lib32-bzip2-1.0.8-4-x86_64                                                               32.4 KiB   295 KiB/s 00:00 [######################################################################] 100% libxrender-0.9.12-1-x86_64                                                               29.4 KiB   438 KiB/s 00:00 [######################################################################] 100% lib32-libxext-1.3.6-1-x86_64                                                             28.9 KiB   590 KiB/s 00:00 [######################################################################] 100% libxrandr-1.5.4-1-x86_64                                                                 27.3 KiB   447 KiB/s 00:00 [######################################################################] 100% libxdmcp-1.1.5-1-x86_64                                                                  27.1 KiB   553 KiB/s 00:00 [######################################################################] 100% libxkbcommon-x11-1.10.0-1-x86_64                                                         26.7 KiB   461 KiB/s 00:00 [######################################################################] 100% libxvmc-1.0.14-1-x86_64                                                                  24.0 KiB   428 KiB/s 00:00 [######################################################################] 100% lib32-lm_sensors-1:3.6.2-2-x86_64                                                        22.8 KiB   356 KiB/s 00:00 [######################################################################] 100% libpciaccess-0.18.1-2-x86_64                                                             21.5 KiB   303 KiB/s 00:00 [######################################################################] 100% lib32-libpciaccess-0.18.1-1-x86_64                                                       18.9 KiB   315 KiB/s 00:00 [######################################################################] 100% lib32-libffi-3.5.1-1-x86_64                                                              18.9 KiB   401 KiB/s 00:00 [######################################################################] 100% libxxf86vm-1.1.6-1-x86_64                                                                15.5 KiB   303 KiB/s 00:00 [######################################################################] 100% libxfixes-6.0.1-2-x86_64                                                                 13.6 KiB   389 KiB/s 00:00 [######################################################################] 100% egl-gbm-1.1.2.1-1-x86_64                                                                 12.6 KiB   361 KiB/s 00:00 [######################################################################] 100% xcb-util-0.4.1-2-x86_64                                                                  11.6 KiB   332 KiB/s 00:00 [######################################################################] 100% libxau-1.0.12-1-x86_64                                                                   11.4 KiB   316 KiB/s 00:00 [######################################################################] 100% lib32-libxdmcp-1.1.5-1-x86_64                                                            10.3 KiB   251 KiB/s 00:00 [######################################################################] 100% lib32-libxxf86vm-1.1.5-2-x86_64                                                           9.2 KiB   249 KiB/s 00:00 [######################################################################] 100% lib32-keyutils-1.6.3-2-x86_64                                                             8.7 KiB   241 KiB/s 00:00 [######################################################################] 100% xcb-util-keysyms-0.4.1-5-x86_64                                                           7.5 KiB   216 KiB/s 00:00 [######################################################################] 100% eglexternalplatform-1.2.1-1-any                                                           7.5 KiB   214 KiB/s 00:00 [######################################################################] 100% libxdamage-1.1.6-2-x86_64                                                                 7.1 KiB   204 KiB/s 00:00 [######################################################################] 100% lib32-libxau-1.0.11-2-x86_64                                                              6.8 KiB   200 KiB/s 00:00 [######################################################################] 100% libxshmfence-1.3.3-1-x86_64                                                               6.0 KiB   171 KiB/s 00:00 [######################################################################] 100% lib32-libxshmfence-1.3.3-1-x86_64                                                         5.1 KiB   151 KiB/s 00:00 [######################################################################] 100% default-cursors-3-1-any                                                                   2.3 KiB  68.1 KiB/s 00:00 [######################################################################] 100% llvm-libs-20.1.8-1-x86_64                                                                37.8 MiB  2.39 MiB/s 00:16 [######################################################################] 100% lib32-gcc-libs-15.1.1+r7+gf36ec88aa85a-1-x86_64                                          31.8 MiB  2018 KiB/s 00:16 [######################################################################] 100% lib32-llvm-libs-1:20.1.8-1-x86_64                                                        42.4 MiB  2.45 MiB/s 00:17 [######################################################################] 100% lib32-nvidia-utils-575.64.03-1-x86_64                                                    51.4 MiB  2.69 MiB/s 00:19 [######################################################################] 100% nvidia-575.64.03-4-x86_64                                                                84.6 MiB  3.83 MiB/s 00:22 [######################################################################] 100% nvidia-utils-575.64.03-1-x86_64                                                         275.9 MiB  8.14 MiB/s 00:34 [######################################################################] 100% Total (100/100)                                                                         588.1 MiB  17.3 MiB/s 00:34 [######################################################################] 100%
(100/100) checking keys in keyring                                                                                   [######################################################################] 100%
(100/100) checking package integrity                                                                                 [######################################################################] 100%
(100/100) loading package files                                                                                      [######################################################################] 100%
(100/100) checking for file conflicts                                                                                [######################################################################] 100%
(100/100) checking available disk space                                                                              [######################################################################] 100%
:: Processing package changes...
(  1/100) installing xcb-proto                                                                                       [######################################################################] 100%
(  2/100) installing xorgproto                                                                                       [######################################################################] 100%
(  3/100) installing libxdmcp                                                                                        [######################################################################] 100%
(  4/100) installing libxau                                                                                          [######################################################################] 100%
(  5/100) installing libxcb                                                                                          [######################################################################] 100%
(  6/100) installing libx11                                                                                          [######################################################################] 100%
(  7/100) installing libxext                                                                                         [######################################################################] 100%
(  8/100) installing libpciaccess                                                                                    [######################################################################] 100%
(  9/100) installing libdrm                                                                                          [######################################################################] 100%
Optional dependencies for libdrm
    cairo: needed for modetest tool [pending]
( 10/100) installing libxshmfence                                                                                    [######################################################################] 100%
( 11/100) installing libxxf86vm                                                                                      [######################################################################] 100%
( 12/100) installing llvm-libs                                                                                       [######################################################################] 100%
( 13/100) installing lm_sensors                                                                                      [######################################################################] 100%
Optional dependencies for lm_sensors
    rrdtool: for logging with sensord
    perl: for sensor detection and configuration convert
( 14/100) installing spirv-tools                                                                                     [######################################################################] 100%
( 15/100) installing default-cursors                                                                                 [######################################################################] 100%
Optional dependencies for default-cursors
    adwaita-cursors: default cursor theme
( 16/100) installing wayland                                                                                         [######################################################################] 100%
( 17/100) installing mesa                                                                                            [######################################################################] 100%
Optional dependencies for mesa
    opengl-man-pages: for the OpenGL API man pages
( 18/100) installing libglvnd                                                                                        [######################################################################] 100%
( 19/100) installing eglexternalplatform                                                                             [######################################################################] 100%
( 20/100) installing egl-wayland                                                                                     [######################################################################] 100%
( 21/100) installing egl-gbm                                                                                         [######################################################################] 100%
( 22/100) installing egl-x11                                                                                         [######################################################################] 100%
( 23/100) installing nvidia-utils                                                                                    [######################################################################] 100%
Created symlink '/etc/systemd/system/systemd-suspend.service.wants/nvidia-resume.service' → '/usr/lib/systemd/system/nvidia-resume.service'.
Created symlink '/etc/systemd/system/systemd-hibernate.service.wants/nvidia-resume.service' → '/usr/lib/systemd/system/nvidia-resume.service'.
Created symlink '/etc/systemd/system/systemd-suspend-then-hibernate.service.wants/nvidia-resume.service' → '/usr/lib/systemd/system/nvidia-resume.service'.
Created symlink '/etc/systemd/system/systemd-hibernate.service.wants/nvidia-hibernate.service' → '/usr/lib/systemd/system/nvidia-hibernate.service'.
Created symlink '/etc/systemd/system/systemd-suspend.service.wants/nvidia-suspend.service' → '/usr/lib/systemd/system/nvidia-suspend.service'.
Optional dependencies for nvidia-utils
    nvidia-settings: configuration tool
    xorg-server: Xorg support
    xorg-server-devel: nvidia-xconfig
    opencl-nvidia: OpenCL support
( 24/100) installing nvidia                                                                                          [######################################################################] 100%
( 25/100) installing lib32-glibc                                                                                     [######################################################################] 100%
( 26/100) installing lib32-zlib                                                                                      [######################################################################] 100%
( 27/100) installing lib32-gcc-libs                                                                                  [######################################################################] 100%
( 28/100) installing lib32-libxdmcp                                                                                  [######################################################################] 100%
( 29/100) installing lib32-libxau                                                                                    [######################################################################] 100%
( 30/100) installing lib32-libxcb                                                                                    [######################################################################] 100%
( 31/100) installing lib32-libx11                                                                                    [######################################################################] 100%
( 32/100) installing lib32-libxext                                                                                   [######################################################################] 100%
( 33/100) installing lib32-expat                                                                                     [######################################################################] 100%
( 34/100) installing lib32-libpciaccess                                                                              [######################################################################] 100%
( 35/100) installing lib32-libdrm                                                                                    [######################################################################] 100%
( 36/100) installing lib32-bzip2                                                                                     [######################################################################] 100%
( 37/100) installing lib32-brotli                                                                                    [######################################################################] 100%
( 38/100) installing lib32-e2fsprogs                                                                                 [######################################################################] 100%
( 39/100) installing lib32-keyutils                                                                                  [######################################################################] 100%
( 40/100) installing lib32-openssl                                                                                   [######################################################################] 100%
Optional dependencies for lib32-openssl
    ca-certificates [installed]
( 41/100) installing lib32-libxcrypt                                                                                 [######################################################################] 100%
( 42/100) installing lib32-libldap                                                                                   [######################################################################] 100%
( 43/100) installing lib32-krb5                                                                                      [######################################################################] 100%
( 44/100) installing lib32-libunistring                                                                              [######################################################################] 100%
( 45/100) installing lib32-libidn2                                                                                   [######################################################################] 100%
( 46/100) installing lib32-libnghttp2                                                                                [######################################################################] 100%
( 47/100) installing lib32-libnghttp3                                                                                [######################################################################] 100%
( 48/100) installing lib32-libpsl                                                                                    [######################################################################] 100%
( 49/100) installing lib32-libssh2                                                                                   [######################################################################] 100%
( 50/100) installing lib32-zstd                                                                                      [######################################################################] 100%
( 51/100) installing lib32-curl                                                                                      [######################################################################] 100%
( 52/100) installing lib32-json-c                                                                                    [######################################################################] 100%
( 53/100) installing lib32-xz                                                                                        [######################################################################] 100%
( 54/100) installing lib32-libelf                                                                                    [######################################################################] 100%
( 55/100) installing lib32-libxshmfence                                                                              [######################################################################] 100%
( 56/100) installing lib32-libxxf86vm                                                                                [######################################################################] 100%
( 57/100) installing lib32-libffi                                                                                    [######################################################################] 100%
( 58/100) installing lib32-ncurses                                                                                   [######################################################################] 100%
( 59/100) installing lib32-icu                                                                                       [######################################################################] 100%
( 60/100) installing lib32-libxml2                                                                                   [######################################################################] 100%
( 61/100) installing lib32-llvm-libs                                                                                 [######################################################################] 100%
( 62/100) installing lib32-lm_sensors                                                                                [######################################################################] 100%
( 63/100) installing lib32-spirv-tools                                                                               [######################################################################] 100%
( 64/100) installing lib32-wayland                                                                                   [######################################################################] 100%
( 65/100) installing lib32-mesa                                                                                      [######################################################################] 100%
Optional dependencies for lib32-mesa
    opengl-man-pages: for the OpenGL API man pages
( 66/100) installing lib32-libglvnd                                                                                  [######################################################################] 100%
( 67/100) installing lib32-nvidia-utils                                                                              [######################################################################] 100%
Optional dependencies for lib32-nvidia-utils
    lib32-opencl-nvidia
( 68/100) installing libxv                                                                                           [######################################################################] 100%
( 69/100) installing libxvmc                                                                                         [######################################################################] 100%
( 70/100) installing pixman                                                                                          [######################################################################] 100%
( 71/100) installing xcb-util                                                                                        [######################################################################] 100%
( 72/100) installing libxfixes                                                                                       [######################################################################] 100%
( 73/100) installing libxrender                                                                                      [######################################################################] 100%
( 74/100) installing libxdamage                                                                                      [######################################################################] 100%
( 75/100) installing xf86-video-intel                                                                                [######################################################################] 100%
>>> This driver now uses DRI3 as the default Direct Rendering
    Infrastructure. You can try falling back to DRI2 if you run
    into trouble. To do so, save a file with the following
    content as /etc/X11/xorg.conf.d/20-intel.conf :
      Section "Device"
        Identifier  "Intel Graphics"
        Driver      "intel"
        Option      "DRI" "2"             # DRI3 is now default
        #Option      "AccelMethod"  "sna" # default
        #Option      "AccelMethod"  "uxa" # fallback
      EndSection
Optional dependencies for xf86-video-intel
    libxrandr: for intel-virtual-output [pending]
    libxinerama: for intel-virtual-output
    libxcursor: for intel-virtual-output
    libxtst: for intel-virtual-output
    libxss: for intel-virtual-output
( 76/100) installing vulkan-icd-loader                                                                               [######################################################################] 100%
Optional dependencies for vulkan-icd-loader
    vulkan-driver: packaged vulkan driver [installed]
( 77/100) installing xcb-util-keysyms                                                                                [######################################################################] 100%
( 78/100) installing vulkan-intel                                                                                    [######################################################################] 100%
Optional dependencies for vulkan-intel
    vulkan-mesa-layers: additional vulkan layers
( 79/100) installing glu                                                                                             [######################################################################] 100%
( 80/100) installing libxi                                                                                           [######################################################################] 100%
( 81/100) installing libxrandr                                                                                       [######################################################################] 100%
( 82/100) installing freeglut                                                                                        [######################################################################] 100%
( 83/100) installing mesa-demos                                                                                      [######################################################################] 100%
( 84/100) installing libpng                                                                                          [######################################################################] 100%
( 85/100) installing graphite                                                                                        [######################################################################] 100%
Optional dependencies for graphite
    graphite-docs: Documentation
( 86/100) installing harfbuzz                                                                                        [######################################################################] 100%
Optional dependencies for harfbuzz
    harfbuzz-utils: utilities
( 87/100) installing freetype2                                                                                       [######################################################################] 100%
( 88/100) installing fontconfig                                                                                      [######################################################################] 100%
Creating fontconfig configuration...
Rebuilding fontconfig cache...
( 89/100) installing lzo                                                                                             [######################################################################] 100%
( 90/100) installing cairo                                                                                           [######################################################################] 100%
( 91/100) installing fribidi                                                                                         [######################################################################] 100%
( 92/100) installing libdatrie                                                                                       [######################################################################] 100%
( 93/100) installing libthai                                                                                         [######################################################################] 100%
( 94/100) installing libxft                                                                                          [######################################################################] 100%
( 95/100) installing pango                                                                                           [######################################################################] 100%
( 96/100) installing libdecor                                                                                        [######################################################################] 100%
Optional dependencies for libdecor
    gtk3: gtk3 support
( 97/100) installing xkeyboard-config                                                                                [######################################################################] 100%
( 98/100) installing libxkbcommon                                                                                    [######################################################################] 100%
Optional dependencies for libxkbcommon
    libxkbcommon-x11: xkbcli interactive-x11 [pending]
    wayland: xkbcli interactive-wayland [installed]
( 99/100) installing libxkbcommon-x11                                                                                [######################################################################] 100%
(100/100) installing mesa-utils                                                                                      [######################################################################] 100%
:: Running post-transaction hooks...
(1/9) Creating system user accounts...
Creating group 'nvidia-persistenced' with GID 143.
Creating user 'nvidia-persistenced' (NVIDIA Persistence Daemon) with UID 143 and GID 143.
(2/9) Reloading system manager configuration...
(3/9) Reloading device manager configuration...
(4/9) Arming ConditionNeedsUpdate...
(5/9) Updating fontconfig configuration...
(6/9) Updating module dependencies...
(7/9) Updating linux initcpios...
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
(8/9) Reloading system bus configuration...
(9/9) Updating fontconfig cache...
```

That is 2G storage gone. AGain, needs revision


Mext we need to incorporate the nvidia_drm module

```shell
[archibold@archibold ~]$ echo "$(cat /etc/kernel/cmdline) nvidia_drm.modeset=1" | sudo tee /etc/kernel/cmdline
[sudo] password for archibold:
root=PARTUUID=75bd02ea-c59a-45be-8b64-e38e088c68ba rw quiet loglevel=3 nvidia_drm.modeset=1
```

Lets rebuild the UKI again...

```shell
[archibold@archibold ~]$ sudo mkinitcpio -p linux
[sudo] password for archibold:    isThisLongEnoughForAreallyLongSecureUncrackablePassword?!22
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


Reboot

```shell
[archibold@archibold ~]$ shutdown -r now
Call to Reboot failed: Access denied
[archibold@archibold ~]$ sudo shutdown -r now
[sudo] password for archibold:

Broadcast message from root@archibold on pts/1 (Tue 2025-07-22 21:33:37 BST):

The system will reboot now!
```


Log in

```PowerShell
PS C:\Users\UserID> ssh archibold@192.168.1.21
archibold@192.168.1.21's password:    ssssshItsASecret
Last login: Tue Jul 22 20:48:10 2025 from 192.168.1.22
```


check lsmod for issues

```shell
[archibold@archibold ~]$ lsmod | grep nvidia
nvidia_drm            143360  0
nvidia_modeset       1843200  1 nvidia_drm
nvidia_uvm           3874816  0
drm_ttm_helper         16384  2 nvidia_drm,xe
video                  81920  3 xe,i915,nvidia_modeset
nvidia              112238592  3 nvidia_uvm,nvidia_drm,nvidia_modeset
```


That looks okay, now let's check to see if the GPU is visable

```
[archibold@archibold ~]$ nvidia-smi
Tue Jul 22 21:36:31 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 575.64.03              Driver Version: 575.64.03      CUDA Version: 12.9     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA RTX A2000 Laptop GPU    Off |   00000000:01:00.0 Off |                  N/A |
| N/A   35C    P3              9W /   35W |       1MiB /   4096MiB |      4%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```


I'm happy the GPU is running.


## LightDM

We need a thing
```shell
[archibold@archibold ~]$ sudo pacman -S lightdm lightdm-gtk-greeter
[sudo] password for archibold:
resolving dependencies...
looking for conflicting packages...

Packages (37) adwaita-cursors-48.1-1  adwaita-fonts-48.2-1  adwaita-icon-theme-48.1-1  adwaita-icon-theme-legacy-46.2-3
              at-spi2-core-2.56.2-1  avahi-1:0.8+r194+g3f79789-3  dav1d-1.5.1-1  dconf-0.40.0-3  desktop-file-utils-0.28-1
              duktape-2.7.0-7  gdk-pixbuf2-2.42.12-2  glib-networking-1:2.80.1-1  gsettings-desktop-schemas-48.0-1
              gsettings-system-schemas-48.0-1  gtk-update-icon-cache-1:4.18.6-1  gtk3-1:3.24.49-2  hicolor-icon-theme-0.18-1
              iso-codes-4.18.0-1  jbigkit-2.1-8  json-glib-1.10.6-1  lcms2-2.17-1  libcloudproviders-0.3.6-2  libcolord-1.4.7-2
              libcups-2:2.4.12-2  libdaemon-0.14-6  libjpeg-turbo-3.1.0-1  libproxy-0.5.9-1  librsvg-2:2.60.0-2  libsoup3-3.6.5-1
              libstemmer-3.0.1-1  libtiff-4.7.0-1  libxklavier-5.4-6  polkit-126-2  shared-mime-info-2.4-2  tinysparql-3.9.2-2
              lightdm-1:1.32.0-6  lightdm-gtk-greeter-1:2.0.9-1

Total Download Size:    27.47 MiB
Total Installed Size:  148.53 MiB

:: Proceed with installation? [Y/n] y
:: Retrieving packages...
 librsvg-2:2.60.0-2-x86_64                                2.3 MiB  3.27 MiB/s 00:01 [################################################] 100%
 adwaita-icon-theme-legacy-46.2-3-any                     2.2 MiB  2.63 MiB/s 00:01 [################################################] 100%
 adwaita-fonts-48.2-1-any                                 2.1 MiB  2.18 MiB/s 00:01 [################################################] 100%
 iso-codes-4.18.0-1-any                                   3.4 MiB  3.16 MiB/s 00:01 [################################################] 100%
 tinysparql-3.9.2-2-x86_64                             1063.4 KiB  2.88 MiB/s 00:00 [################################################] 100%
 gsettings-desktop-schemas-48.0-1-any                   733.3 KiB  1482 KiB/s 00:00 [################################################] 100%
 dav1d-1.5.1-1-x86_64                                   639.2 KiB  1175 KiB/s 00:01 [################################################] 100%
 shared-mime-info-2.4-2-x86_64                          614.4 KiB  1969 KiB/s 00:00 [################################################] 100%
 at-spi2-core-2.56.2-1-x86_64                           572.9 KiB  2003 KiB/s 00:00 [################################################] 100%
 gtk3-1:3.24.49-2-x86_64                                  8.7 MiB  4.46 MiB/s 00:02 [################################################] 100%
 libjpeg-turbo-3.1.0-1-x86_64                           568.5 KiB  1238 KiB/s 00:00 [################################################] 100%
 gdk-pixbuf2-2.42.12-2-x86_64                           518.4 KiB  1168 KiB/s 00:00 [################################################] 100%
 libtiff-4.7.0-1-x86_64                                 496.1 KiB  1344 KiB/s 00:00 [################################################] 100%
 avahi-1:0.8+r194+g3f79789-3-x86_64                     426.3 KiB  2001 KiB/s 00:00 [################################################] 100%
 polkit-126-2-x86_64                                    403.2 KiB  2.09 MiB/s 00:00 [################################################] 100%
 libsoup3-3.6.5-1-x86_64                                392.6 KiB  2.23 MiB/s 00:00 [################################################] 100%
 adwaita-cursors-48.1-1-any                             360.0 KiB  1690 KiB/s 00:00 [################################################] 100%
 libcups-2:2.4.12-2-x86_64                              272.2 KiB  1512 KiB/s 00:00 [################################################] 100%
 lightdm-1:1.32.0-6-x86_64                              234.5 KiB  1532 KiB/s 00:00 [################################################] 100%
 lcms2-2.17-1-x86_64                                    220.0 KiB  2.29 MiB/s 00:00 [################################################] 100%
 adwaita-icon-theme-48.1-1-any                          198.5 KiB  1927 KiB/s 00:00 [################################################] 100%
 libcolord-1.4.7-2-x86_64                               186.8 KiB  2.40 MiB/s 00:00 [################################################] 100%
 duktape-2.7.0-7-x86_64                                 176.2 KiB  2026 KiB/s 00:00 [################################################] 100%
 json-glib-1.10.6-1-x86_64                              172.1 KiB  2.18 MiB/s 00:00 [################################################] 100%
 glib-networking-1:2.80.1-1-x86_64                      140.4 KiB  2.49 MiB/s 00:00 [################################################] 100%
 libstemmer-3.0.1-1-x86_64                              135.4 KiB  2.70 MiB/s 00:00 [################################################] 100%
 dconf-0.40.0-3-x86_64                                  105.4 KiB  2.10 MiB/s 00:00 [################################################] 100%
 lightdm-gtk-greeter-1:2.0.9-1-x86_64                    93.5 KiB  1949 KiB/s 00:00 [################################################] 100%
 libcloudproviders-0.3.6-2-x86_64                        63.6 KiB  3.88 MiB/s 00:00 [################################################] 100%
 libxklavier-5.4-6-x86_64                                68.0 KiB  1511 KiB/s 00:00 [################################################] 100%
 jbigkit-2.1-8-x86_64                                    52.2 KiB  2.55 MiB/s 00:00 [################################################] 100%
 desktop-file-utils-0.28-1-x86_64                        42.5 KiB  1773 KiB/s 00:00 [################################################] 100%
 libproxy-0.5.9-1-x86_64                                 29.5 KiB  1134 KiB/s 00:00 [################################################] 100%
 libdaemon-0.14-6-x86_64                                 19.2 KiB  1129 KiB/s 00:00 [################################################] 100%
 gtk-update-icon-cache-1:4.18.6-1-x86_64                 16.8 KiB   648 KiB/s 00:00 [################################################] 100%
 hicolor-icon-theme-0.18-1-any                           13.0 KiB   814 KiB/s 00:00 [################################################] 100%
 gsettings-system-schemas-48.0-1-any                      5.9 KiB   279 KiB/s 00:00 [################################################] 100%
 Total (37/37)                                           27.5 MiB  10.3 MiB/s 00:03 [################################################] 100%
(37/37) checking keys in keyring                                                    [################################################] 100%
(37/37) checking package integrity                                                  [################################################] 100%
(37/37) loading package files                                                       [################################################] 100%
(37/37) checking for file conflicts                                                 [################################################] 100%
(37/37) checking available disk space                                               [################################################] 100%
:: Processing package changes...
( 1/37) installing iso-codes                                                        [################################################] 100%
( 2/37) installing libxklavier                                                      [################################################] 100%
( 3/37) installing duktape                                                          [################################################] 100%
( 4/37) installing polkit                                                           [################################################] 100%
( 5/37) installing lightdm                                                          [################################################] 100%
Optional dependencies for lightdm
    accountsservice: Enhanced user accounts handling
    lightdm-gtk-greeter: GTK greeter [pending]
    xorg-server-xephyr: LightDM test mode [installed]
( 6/37) installing adwaita-fonts                                                    [################################################] 100%
( 7/37) installing hicolor-icon-theme                                               [################################################] 100%
( 8/37) installing adwaita-icon-theme-legacy                                        [################################################] 100%
( 9/37) installing adwaita-cursors                                                  [################################################] 100%
(10/37) installing adwaita-icon-theme                                               [################################################] 100%
(11/37) installing dconf                                                            [################################################] 100%
(12/37) installing gsettings-system-schemas                                         [################################################] 100%
(13/37) installing gsettings-desktop-schemas                                        [################################################] 100%
(14/37) installing at-spi2-core                                                     [################################################] 100%
(15/37) installing desktop-file-utils                                               [################################################] 100%
(16/37) installing libjpeg-turbo                                                    [################################################] 100%
Optional dependencies for libjpeg-turbo
    java-runtime>11: for TurboJPEG Java wrapper
(17/37) installing jbigkit                                                          [################################################] 100%
(18/37) installing libtiff                                                          [################################################] 100%
Optional dependencies for libtiff
    freeglut: for using tiffgt [installed]
(19/37) installing shared-mime-info                                                 [################################################] 100%
(20/37) installing gdk-pixbuf2                                                      [################################################] 100%
Optional dependencies for gdk-pixbuf2
    libwmf: Load .wmf and .apm
    libopenraw: Load .dng, .cr2, .crw, .nef, .orf, .pef, .arw, .erf, .mrw, and .raf
    libavif: Load .avif
    libheif: Load .heif, .heic, and .avif
    libjxl: Load .jxl
    librsvg: Load .svg, .svgz, and .svg.gz [pending]
    webp-pixbuf-loader: Load .webp
(21/37) installing libcloudproviders                                                [################################################] 100%
(22/37) installing lcms2                                                            [################################################] 100%
(23/37) installing libcolord                                                        [################################################] 100%
(24/37) installing libdaemon                                                        [################################################] 100%
(25/37) installing avahi                                                            [################################################] 100%
Optional dependencies for avahi
    gtk3: avahi-discover, avahi-discover-standalone, bshell, bssh, bvnc [pending]
    libevent: libevent bindings [installed]
    nss-mdns: NSS support for mDNS
    python-dbus: avahi-bookmarks, avahi-discover
    python-gobject: avahi-bookmarks, avahi-discover
    python-twisted: avahi-bookmarks
    qt5-base: qt5 bindings
(26/37) installing libcups                                                          [################################################] 100%
(27/37) installing dav1d                                                            [################################################] 100%
Optional dependencies for dav1d
    dav1d-doc: HTML documentation
(28/37) installing librsvg                                                          [################################################] 100%
(29/37) installing json-glib                                                        [################################################] 100%
(30/37) installing libproxy                                                         [################################################] 100%
(31/37) installing glib-networking                                                  [################################################] 100%
(32/37) installing libsoup3                                                         [################################################] 100%
Optional dependencies for libsoup3
    samba: Windows Domain SSO
(33/37) installing libstemmer                                                       [################################################] 100%
(34/37) installing tinysparql                                                       [################################################] 100%
(35/37) installing gtk-update-icon-cache                                            [################################################] 100%
(36/37) installing gtk3                                                             [################################################] 100%
Optional dependencies for gtk3
    evince: Default print preview command
(37/37) installing lightdm-gtk-greeter                                              [################################################] 100%
:: Running post-transaction hooks...
( 1/15) Creating system user accounts...
Creating group 'polkitd' with GID 102.
Creating group 'avahi' with GID 971.
Creating user 'avahi' (Avahi mDNS/DNS-SD daemon) with UID 971 and GID 971.
Creating group 'lightdm' with GID 970.
Creating user 'lightdm' (Light Display Manager) with UID 970 and GID 970.
Creating user 'polkitd' (User for polkitd) with UID 102 and GID 102.
( 2/15) Reloading system manager configuration...
( 3/15) Reloading user manager configuration...
( 4/15) Creating temporary files...
( 5/15) Arming ConditionNeedsUpdate...
( 6/15) Updating the MIME type database...
( 7/15) Reloading system bus configuration...
( 8/15) Updating fontconfig cache...
( 9/15) Probing GDK-Pixbuf loader modules...
(10/15) Updating GIO module cache...
(11/15) Compiling GSettings XML schema files...
(12/15) Probing GTK3 input method modules...
(13/15) Updating icon theme caches...
(14/15) Updating the desktop file MIME type cache...
(15/15) Updating X fontdir indices...
```

Then enable that shit

```shell
[archibold@archibold ~]$ sudo systemctl enable --now lightdm
Created symlink '/etc/systemd/system/display-manager.service' → '/usr/lib/systemd/system/lightdm.service'.
```


## i3 WM

Install the packages `i3-wm`, `i3status`, `i3lock`, `dmenu`, `xorg`, `xorg-xinit`, and `xterm`.

```shell
[archibold@archibold ~]$ sudo pacman -S i3-wm i3status i3lock dmenu xorg xorg-xinit xterm
[sudo] password for archibold:
:: There are 48 members in group xorg:
:: Repository extra
   1) xf86-video-vesa  2) xorg-bdftopcf  3) xorg-docs  4) xorg-font-util  5) xorg-fonts-100dpi  6) xorg-fonts-75dpi
   7) xorg-fonts-encodings  8) xorg-iceauth  9) xorg-mkfontscale  10) xorg-server  11) xorg-server-common  12) xorg-server-devel
   13) xorg-server-xephyr  14) xorg-server-xnest  15) xorg-server-xvfb  16) xorg-sessreg  17) xorg-setxkbmap  18) xorg-smproxy
   19) xorg-x11perf  20) xorg-xauth  21) xorg-xbacklight  22) xorg-xcmsdb  23) xorg-xcursorgen  24) xorg-xdpyinfo  25) xorg-xdriinfo
   26) xorg-xev  27) xorg-xgamma  28) xorg-xhost  29) xorg-xinput  30) xorg-xkbcomp  31) xorg-xkbevd  32) xorg-xkbutils  33) xorg-xkill
   34) xorg-xlsatoms  35) xorg-xlsclients  36) xorg-xmodmap  37) xorg-xpr  38) xorg-xprop  39) xorg-xrandr  40) xorg-xrdb
   41) xorg-xrefresh  42) xorg-xset  43) xorg-xsetroot  44) xorg-xvinfo  45) xorg-xwayland  46) xorg-xwd  47) xorg-xwininfo  48) xorg-xwud

Enter a selection (default=all):
resolving dependencies...
:: There are 11 providers available for ttf-font:
:: Repository extra
   1) gnu-free-fonts  2) noto-fonts  3) ttf-bitstream-vera  4) ttf-croscore  5) ttf-dejavu  6) ttf-droid  7) ttf-ibm-plex  8) ttf-input
   9) ttf-input-nerd  10) ttf-liberation  11) ttf-roboto

Enter a number (default=1):
:: There are 2 providers available for man:
:: Repository core
   1) man-db
:: Repository extra
   2) mandoc

Enter a number (default=1):
looking for conflicting packages...

Packages (111) alsa-lib-1.2.14-1  alsa-topology-conf-1.2.5.1-4  alsa-ucm-conf-1.2.14-2  confuse-3.3-4  db5.3-5.3.28-5  flac-1.5.0-1
               gnu-free-fonts-20120503-8  groff-1.23.0-7  lame-3.100-5  less-1:668-1  libasyncns-1:0.8+r3+g68cd5af-3  libei-1.4.1-1
               libepoxy-1.5.10-3  libev-4.33-3  libevdev-1.13.4-1  libfontenc-1.1.8-1  libgudev-238-3  libice-1.1.2-1  libinput-1.28.1-1
               libogg-1.3.5-2  libpipeline-1.5.8-1  libpulse-17.0+r43+g3e2bb8a1e-1  libsm-1.2.6-1  libsndfile-1.2.2-3  libunwind-1.8.1-3
               libutempter-1.2.3-1  libvorbis-1.3.7-4  libwacom-2.16.1-1  libxaw-1.0.16-1  libxcomposite-0.4.6-2  libxcursor-1.2.3-1
               libxcvt-0.1.3-1  libxfont2-2.0.7-1  libxinerama-1.1.5-2  libxkbfile-1.1.3-1  libxmu-1.2.1-1  libxpm-3.5.17-2  libxt-1.3.1-1
               libxtst-1.2.5-1  luit-20240910-1  man-db-2.13.1-1  mpg123-1.33.0-1  mtdev-1.1.7-1  opus-1.5.2-1  perl-5.40.2-1
               startup-notification-0.12-8  xbitmaps-1.1.3-2  xcb-util-cursor-0.1.5-1  xcb-util-image-0.4.1-3
               xcb-util-renderutil-0.3.10-2  xcb-util-wm-0.4.2-2  xcb-util-xrm-1.3-3  xf86-input-libinput-1.5.0-1
               xorg-fonts-alias-100dpi-1.0.5-1  xorg-fonts-alias-75dpi-1.0.5-1  xorg-util-macros-1.20.2-1  yajl-2.1.0-6  dmenu-5.3-3
               i3-wm-4.24-1  i3lock-2.15-2  i3status-2.15-1  xf86-video-vesa-2.6.0-2  xorg-bdftopcf-1.1.2-1  xorg-docs-1.7.3-2
               xorg-font-util-1.4.1-2  xorg-fonts-100dpi-1.0.4-3  xorg-fonts-75dpi-1.0.4-2  xorg-fonts-encodings-1.1.0-1
               xorg-iceauth-1.0.10-1  xorg-mkfontscale-1.2.3-1  xorg-server-21.1.18-2  xorg-server-common-21.1.18-2
               xorg-server-devel-21.1.18-2  xorg-server-xephyr-21.1.18-2  xorg-server-xnest-21.1.18-2  xorg-server-xvfb-21.1.18-2
               xorg-sessreg-1.1.4-1  xorg-setxkbmap-1.3.4-2  xorg-smproxy-1.0.8-1  xorg-x11perf-1.7.0-1  xorg-xauth-1.1.4-1
               xorg-xbacklight-1.2.4-1  xorg-xcmsdb-1.0.7-1  xorg-xcursorgen-1.0.9-1  xorg-xdpyinfo-1.3.4-2  xorg-xdriinfo-1.0.7-2
               xorg-xev-1.2.6-1  xorg-xgamma-1.0.7-2  xorg-xhost-1.0.10-1  xorg-xinit-1.4.4-1  xorg-xinput-1.6.4-2  xorg-xkbcomp-1.4.7-1
               xorg-xkbevd-1.1.6-1  xorg-xkbutils-1.0.6-1  xorg-xkill-1.0.6-2  xorg-xlsatoms-1.1.4-2  xorg-xlsclients-1.1.5-2
               xorg-xmodmap-1.0.11-2  xorg-xpr-1.2.0-1  xorg-xprop-1.2.8-1  xorg-xrandr-1.5.3-1  xorg-xrdb-1.2.2-2  xorg-xrefresh-1.1.0-1
               xorg-xset-1.2.5-2  xorg-xsetroot-1.1.3-2  xorg-xvinfo-1.1.5-2  xorg-xwayland-24.1.8-1  xorg-xwd-1.0.9-2
               xorg-xwininfo-1.1.6-2  xorg-xwud-1.0.7-1  xterm-400-1

Total Download Size:    68.08 MiB
Total Installed Size:  166.73 MiB

:: Proceed with installation? [Y/n]
:: Retrieving packages...
 gnu-free-fonts-20120503-8-any                            3.2 MiB  3.32 MiB/s 00:01 [################################################] 100%
 opus-1.5.2-1-x86_64                                      4.3 MiB  3.08 MiB/s 00:01 [################################################] 100%
 xorg-fonts-75dpi-1.0.4-2-any                            10.3 MiB  6.94 MiB/s 00:01 [################################################] 100%
 groff-1.23.0-7-x86_64                                    2.3 MiB  2.39 MiB/s 00:01 [################################################] 100%
 db5.3-5.3.28-5-x86_64                                 1213.0 KiB  2.23 MiB/s 00:01 [################################################] 100%
 xorg-server-21.1.18-2-x86_64                          1507.7 KiB  2.33 MiB/s 00:01 [################################################] 100%
 man-db-2.13.1-1-x86_64                                1169.0 KiB  4.80 MiB/s 00:00 [################################################] 100%
 xorg-server-xephyr-21.1.18-2-x86_64                    965.9 KiB  4.16 MiB/s 00:00 [################################################] 100%
 xorg-xwayland-24.1.8-1-x86_64                          959.8 KiB  3.65 MiB/s 00:00 [################################################] 100%
 i3-wm-4.24-1-x86_64                                    941.5 KiB  8.36 MiB/s 00:00 [################################################] 100%
 xorg-server-xvfb-21.1.18-2-x86_64                      812.2 KiB  3.64 MiB/s 00:00 [################################################] 100%
 xorg-server-xnest-21.1.18-2-x86_64                     618.7 KiB  3.10 MiB/s 00:00 [################################################] 100%
 xorg-fonts-encodings-1.1.0-1-any                       569.8 KiB  6.87 MiB/s 00:00 [################################################] 100%
 libxt-1.3.1-1-x86_64                                   527.6 KiB  4.73 MiB/s 00:00 [################################################] 100%
 alsa-lib-1.2.14-1-x86_64                               491.5 KiB  3.38 MiB/s 00:00 [################################################] 100%
 xterm-400-1-x86_64                                     453.3 KiB  4.86 MiB/s 00:00 [################################################] 100%
 mpg123-1.33.0-1-x86_64                                 450.2 KiB  3.52 MiB/s 00:00 [################################################] 100%
 libpulse-17.0+r43+g3e2bb8a1e-1-x86_64                  400.2 KiB  2.73 MiB/s 00:00 [################################################] 100%
 libxaw-1.0.16-1-x86_64                                 354.5 KiB  5.02 MiB/s 00:00 [################################################] 100%
 flac-1.5.0-1-x86_64                                    335.2 KiB  3.31 MiB/s 00:00 [################################################] 100%
 lame-3.100-5-x86_64                                    330.3 KiB  3.23 MiB/s 00:00 [################################################] 100%
 libsndfile-1.2.2-3-x86_64                              315.5 KiB  5.50 MiB/s 00:00 [################################################] 100%
 libinput-1.28.1-1-x86_64                               306.3 KiB  5.34 MiB/s 00:00 [################################################] 100%
 libepoxy-1.5.10-3-x86_64                               305.3 KiB  4.89 MiB/s 00:00 [################################################] 100%
 xorg-server-devel-21.1.18-2-x86_64                     201.2 KiB  3.78 MiB/s 00:00 [################################################] 100%
 xorg-docs-1.7.3-2-any                                  198.4 KiB  3.18 MiB/s 00:00 [################################################] 100%
 libogg-1.3.5-2-x86_64                                  197.5 KiB  3.57 MiB/s 00:00 [################################################] 100%
 libvorbis-1.3.7-4-x86_64                               182.0 KiB  3.78 MiB/s 00:00 [################################################] 100%
 libwacom-2.16.1-1-x86_64                               175.7 KiB  3.12 MiB/s 00:00 [################################################] 100%
 less-1:668-1-x86_64                                    142.4 KiB  3.16 MiB/s 00:00 [################################################] 100%
 libunwind-1.8.1-3-x86_64                               127.6 KiB  2.97 MiB/s 00:00 [################################################] 100%
 libev-4.33-3-x86_64                                    120.0 KiB  2.79 MiB/s 00:00 [################################################] 100%
 libxfont2-2.0.7-1-x86_64                               113.2 KiB  2.83 MiB/s 00:00 [################################################] 100%
 alsa-ucm-conf-1.2.14-2-any                             112.1 KiB  2.81 MiB/s 00:00 [################################################] 100%
 libei-1.4.1-1-x86_64                                   104.2 KiB  2.31 MiB/s 00:00 [################################################] 100%
 xorg-xkbcomp-1.4.7-1-x86_64                             90.0 KiB  2.44 MiB/s 00:00 [################################################] 100%
 libice-1.1.2-1-x86_64                                   79.1 KiB  2.21 MiB/s 00:00 [################################################] 100%
 libxkbfile-1.1.3-1-x86_64                               76.5 KiB  2.08 MiB/s 00:00 [################################################] 100%
 libxmu-1.2.1-1-x86_64                                   75.1 KiB  2.29 MiB/s 00:00 [################################################] 100%
 xorg-x11perf-1.7.0-1-x86_64                             62.4 KiB  2.54 MiB/s 00:00 [################################################] 100%
 libxpm-3.5.17-2-x86_64                                  71.6 KiB  1704 KiB/s 00:00 [################################################] 100%
 libevdev-1.13.4-1-x86_64                                58.2 KiB  2.27 MiB/s 00:00 [################################################] 100%
 i3status-2.15-1-x86_64                                  54.2 KiB  2.52 MiB/s 00:00 [################################################] 100%
 yajl-2.1.0-6-x86_64                                     50.1 KiB  2.58 MiB/s 00:00 [################################################] 100%
 xorg-fonts-100dpi-1.0.4-3-any                           11.9 MiB  3.36 MiB/s 00:04 [################################################] 100%
 libsm-1.2.6-1-x86_64                                    45.6 KiB  2.12 MiB/s 00:00 [################################################] 100%
 confuse-3.3-4-x86_64                                    44.3 KiB  2.16 MiB/s 00:00 [################################################] 100%
 libgudev-238-3-x86_64                                   43.6 KiB  1743 KiB/s 00:00 [################################################] 100%
 xf86-input-libinput-1.5.0-1-x86_64                      41.9 KiB  1997 KiB/s 00:00 [################################################] 100%
 libpipeline-1.5.8-1-x86_64                              40.7 KiB  2.49 MiB/s 00:00 [################################################] 100%
 xorg-xrandr-1.5.3-1-x86_64                              37.6 KiB  2.62 MiB/s 00:00 [################################################] 100%
 xorg-font-util-1.4.1-2-x86_64                           33.1 KiB  1577 KiB/s 00:00 [################################################] 100%
 xcb-util-wm-0.4.2-2-x86_64                              33.0 KiB  1650 KiB/s 00:00 [################################################] 100%
 libxcursor-1.2.3-1-x86_64                               33.0 KiB  1735 KiB/s 00:00 [################################################] 100%
 perl-5.40.2-1-x86_64                                    20.0 MiB  5.54 MiB/s 00:04 [################################################] 100%
 xorg-xpr-1.2.0-1-x86_64                                 30.8 KiB  1232 KiB/s 00:00 [################################################] 100%
 luit-20240910-1-x86_64                                  29.3 KiB  2.86 MiB/s 00:00 [################################################] 100%
 libxtst-1.2.5-1-x86_64                                  29.0 KiB  1811 KiB/s 00:00 [################################################] 100%
 xorg-xinput-1.6.4-2-x86_64                              27.6 KiB  1625 KiB/s 00:00 [################################################] 100%
 xorg-server-common-21.1.18-2-x86_64                     27.5 KiB  1966 KiB/s 00:00 [################################################] 100%
 xorg-xprop-1.2.8-1-x86_64                               25.8 KiB  1515 KiB/s 00:00 [################################################] 100%
 xbitmaps-1.1.3-2-any                                    24.9 KiB  1185 KiB/s 00:00 [################################################] 100%
 xorg-xauth-1.1.4-1-x86_64                               23.9 KiB  1595 KiB/s 00:00 [################################################] 100%
 xorg-util-macros-1.20.2-1-any                           23.7 KiB  1249 KiB/s 00:00 [################################################] 100%
 xorg-bdftopcf-1.1.2-1-x86_64                            23.6 KiB  1074 KiB/s 00:00 [################################################] 100%
 i3lock-2.15-2-x86_64                                    23.3 KiB   862 KiB/s 00:00 [################################################] 100%
 xorg-mkfontscale-1.2.3-1-x86_64                         23.1 KiB  1154 KiB/s 00:00 [################################################] 100%
 xorg-xwininfo-1.1.6-2-x86_64                            22.7 KiB  1747 KiB/s 00:00 [################################################] 100%
 xorg-xmodmap-1.0.11-2-x86_64                            22.1 KiB  1702 KiB/s 00:00 [################################################] 100%
 dmenu-5.3-3-x86_64                                      20.3 KiB   969 KiB/s 00:00 [################################################] 100%
 xorg-xrdb-1.2.2-2-x86_64                                20.1 KiB   875 KiB/s 00:00 [################################################] 100%
 xorg-xset-1.2.5-2-x86_64                                19.3 KiB  1481 KiB/s 00:00 [################################################] 100%
 xorg-xkbutils-1.0.6-1-x86_64                            18.9 KiB   901 KiB/s 00:00 [################################################] 100%
 startup-notification-0.12-8-x86_64                      18.8 KiB  1251 KiB/s 00:00 [################################################] 100%
 xorg-xinit-1.4.4-1-x86_64                               18.4 KiB   767 KiB/s 00:00 [################################################] 100%
 xorg-xkbevd-1.1.6-1-x86_64                              18.0 KiB   902 KiB/s 00:00 [################################################] 100%
 xorg-xwd-1.0.9-2-x86_64                                 17.5 KiB  1457 KiB/s 00:00 [################################################] 100%
 xcb-util-image-0.4.1-3-x86_64                           17.3 KiB  1236 KiB/s 00:00 [################################################] 100%
 libasyncns-1:0.8+r3+g68cd5af-3-x86_64                   16.9 KiB   845 KiB/s 00:00 [################################################] 100%
 mtdev-1.1.7-1-x86_64                                    16.8 KiB   886 KiB/s 00:00 [################################################] 100%
 xorg-xcmsdb-1.0.7-1-x86_64                              16.7 KiB  1196 KiB/s 00:00 [################################################] 100%
 xorg-iceauth-1.0.10-1-x86_64                            16.4 KiB   714 KiB/s 00:00 [################################################] 100%
 xf86-video-vesa-2.6.0-2-x86_64                          16.3 KiB  1016 KiB/s 00:00 [################################################] 100%
 xorg-xwud-1.0.7-1-x86_64                                16.0 KiB  1001 KiB/s 00:00 [################################################] 100%
 xorg-xdpyinfo-1.3.4-2-x86_64                            16.0 KiB   727 KiB/s 00:00 [################################################] 100%
 libfontenc-1.1.8-1-x86_64                               15.4 KiB  1099 KiB/s 00:00 [################################################] 100%
 xorg-xev-1.2.6-1-x86_64                                 15.3 KiB   957 KiB/s 00:00 [################################################] 100%
 xcb-util-xrm-1.3-3-x86_64                               14.5 KiB   691 KiB/s 00:00 [################################################] 100%
 xorg-setxkbmap-1.3.4-2-x86_64                           13.8 KiB   809 KiB/s 00:00 [################################################] 100%
 alsa-topology-conf-1.2.5.1-4-any                        13.5 KiB  1039 KiB/s 00:00 [################################################] 100%
 xorg-smproxy-1.0.8-1-x86_64                             13.0 KiB   865 KiB/s 00:00 [################################################] 100%
 xorg-xhost-1.0.10-1-x86_64                              12.0 KiB   803 KiB/s 00:00 [################################################] 100%
 xcb-util-cursor-0.1.5-1-x86_64                          11.6 KiB   895 KiB/s 00:00 [################################################] 100%
 libxcomposite-0.4.6-2-x86_64                            11.6 KiB   825 KiB/s 00:00 [################################################] 100%
 xorg-xsetroot-1.1.3-2-x86_64                            11.3 KiB   537 KiB/s 00:00 [################################################] 100%
 libxcvt-0.1.3-1-x86_64                                  10.8 KiB   898 KiB/s 00:00 [################################################] 100%
 xorg-xlsclients-1.1.5-2-x86_64                          10.3 KiB   733 KiB/s 00:00 [################################################] 100%
 libxinerama-1.1.5-2-x86_64                               9.8 KiB   517 KiB/s 00:00 [################################################] 100%
 xorg-xcursorgen-1.0.9-1-x86_64                           9.5 KiB   731 KiB/s 00:00 [################################################] 100%
 libutempter-1.2.3-1-x86_64                               9.4 KiB   447 KiB/s 00:00 [################################################] 100%
 xcb-util-renderutil-0.3.10-2-x86_64                      9.3 KiB   517 KiB/s 00:00 [################################################] 100%
 xorg-xkill-1.0.6-2-x86_64                                9.3 KiB   662 KiB/s 00:00 [################################################] 100%
 xorg-sessreg-1.1.4-1-x86_64                              9.2 KiB   512 KiB/s 00:00 [################################################] 100%
 xorg-xrefresh-1.1.0-1-x86_64                             9.1 KiB   697 KiB/s 00:00 [################################################] 100%
 xorg-xbacklight-1.2.4-1-x86_64                           8.7 KiB   547 KiB/s 00:00 [################################################] 100%
 xorg-xgamma-1.0.7-2-x86_64                               8.7 KiB   436 KiB/s 00:00 [################################################] 100%
 xorg-xvinfo-1.1.5-2-x86_64                               8.4 KiB   601 KiB/s 00:00 [################################################] 100%
 xorg-xlsatoms-1.1.4-2-x86_64                             8.1 KiB   507 KiB/s 00:00 [################################################] 100%
 xorg-xdriinfo-1.0.7-2-x86_64                             6.7 KiB   419 KiB/s 00:00 [################################################] 100%
 xorg-fonts-alias-100dpi-1.0.5-1-any                      3.0 KiB   228 KiB/s 00:00 [################################################] 100%
 xorg-fonts-alias-75dpi-1.0.5-1-any                       3.0 KiB   227 KiB/s 00:00 [################################################] 100%
 Total (111/111)                                         68.1 MiB  17.0 MiB/s 00:04 [################################################] 100%
(111/111) checking keys in keyring                                                  [################################################] 100%
(111/111) checking package integrity                                                [################################################] 100%
(111/111) loading package files                                                     [################################################] 100%
(111/111) checking for file conflicts                                               [################################################] 100%
(111/111) checking available disk space                                             [################################################] 100%
:: Processing package changes...
(  1/111) installing libev                                                          [################################################] 100%
(  2/111) installing startup-notification                                           [################################################] 100%
(  3/111) installing gnu-free-fonts                                                 [################################################] 100%
(  4/111) installing xcb-util-renderutil                                            [################################################] 100%
(  5/111) installing xcb-util-image                                                 [################################################] 100%
(  6/111) installing xcb-util-cursor                                                [################################################] 100%
(  7/111) installing xcb-util-wm                                                    [################################################] 100%
(  8/111) installing xcb-util-xrm                                                   [################################################] 100%
(  9/111) installing yajl                                                           [################################################] 100%
( 10/111) installing i3-wm                                                          [################################################] 100%
Optional dependencies for i3-wm
    dmenu: for the default program launcher [pending]
    rofi: for a modern dmenu replacement
    i3lock: for the default screen locker [pending]
    xss-lock: for the default screen locker
    i3status: for the default status bar generator [pending]
    perl: for i3-save-tree and i3-dmenu-desktop [pending]
    perl-anyevent-i3: for i3-save-tree
    perl-json-xs: for i3-save-tree
( 11/111) installing alsa-topology-conf                                             [################################################] 100%
( 12/111) installing alsa-ucm-conf                                                  [################################################] 100%
( 13/111) installing alsa-lib                                                       [################################################] 100%
( 14/111) installing confuse                                                        [################################################] 100%
( 15/111) installing libasyncns                                                     [################################################] 100%
( 16/111) installing libogg                                                         [################################################] 100%
( 17/111) installing flac                                                           [################################################] 100%
( 18/111) installing lame                                                           [################################################] 100%
( 19/111) installing libvorbis                                                      [################################################] 100%
( 20/111) installing mpg123                                                         [################################################] 100%
Optional dependencies for mpg123
    sdl2: for sdl audio support
    jack: for jack audio support
    libpulse: for pulse audio support [pending]
    perl: for conplay [pending]
( 21/111) installing opus                                                           [################################################] 100%
( 22/111) installing libsndfile                                                     [################################################] 100%
Optional dependencies for libsndfile
    alsa-lib: for sndfile-play [installed]
( 23/111) installing libpulse                                                       [################################################] 100%
Optional dependencies for libpulse
    pulse-native-provider: PulseAudio backend
( 24/111) installing i3status                                                       [################################################] 100%
( 25/111) installing i3lock                                                         [################################################] 100%
( 26/111) installing libxinerama                                                    [################################################] 100%
( 27/111) installing dmenu                                                          [################################################] 100%
( 28/111) installing xf86-video-vesa                                                [################################################] 100%
( 29/111) installing xorg-bdftopcf                                                  [################################################] 100%
( 30/111) installing db5.3                                                          [################################################] 100%
( 31/111) installing perl                                                           [################################################] 100%
( 32/111) installing groff                                                          [################################################] 100%
Optional dependencies for groff
    netpbm: for use together with man -H command interaction in browsers
    psutils: for use together with man -H command interaction in browsers
    libxaw: for gxditview [pending]
    perl-file-homedir: for use with glilypond
( 33/111) installing libpipeline                                                    [################################################] 100%
( 34/111) installing less                                                           [################################################] 100%
( 35/111) installing man-db                                                         [################################################] 100%
Optional dependencies for man-db
    gzip [installed]
( 36/111) installing xorg-docs                                                      [################################################] 100%
( 37/111) installing xorg-font-util                                                 [################################################] 100%
( 38/111) installing xorg-fonts-alias-100dpi                                        [################################################] 100%
( 39/111) installing xorg-fonts-100dpi                                              [################################################] 100%
( 40/111) installing xorg-fonts-alias-75dpi                                         [################################################] 100%
( 41/111) installing xorg-fonts-75dpi                                               [################################################] 100%
( 42/111) installing xorg-fonts-encodings                                           [################################################] 100%
( 43/111) installing libice                                                         [################################################] 100%
( 44/111) installing xorg-iceauth                                                   [################################################] 100%
( 45/111) installing libfontenc                                                     [################################################] 100%
( 46/111) installing xorg-mkfontscale                                               [################################################] 100%
Creating X fontdir indices... done.
( 47/111) installing libepoxy                                                       [################################################] 100%
( 48/111) installing libxfont2                                                      [################################################] 100%
( 49/111) installing libxkbfile                                                     [################################################] 100%
( 50/111) installing xorg-xkbcomp                                                   [################################################] 100%
( 51/111) installing xorg-setxkbmap                                                 [################################################] 100%
( 52/111) installing xorg-server-common                                             [################################################] 100%
( 53/111) installing libunwind                                                      [################################################] 100%
( 54/111) installing mtdev                                                          [################################################] 100%
( 55/111) installing libevdev                                                       [################################################] 100%
( 56/111) installing libgudev                                                       [################################################] 100%
( 57/111) installing libwacom                                                       [################################################] 100%
Optional dependencies for libwacom
    python-libevdev: for libwacom-show-stylus
    python-pyudev: for libwacom-show-stylus
( 58/111) installing libinput                                                       [################################################] 100%
Optional dependencies for libinput
    gtk4: libinput debug-gui
    python-pyudev: libinput measure
    python-libevdev: libinput measure
    python-yaml: used by various tools
( 59/111) installing xf86-input-libinput                                            [################################################] 100%
( 60/111) installing libxcvt                                                        [################################################] 100%
( 61/111) installing xorg-server                                                    [################################################] 100%
>>> xorg-server has now the ability to run without root rights with
    the help of systemd-logind. xserver will fail to run if not launched
    from the same virtual terminal as was used to log in.
    Without root rights, log files will be in ~/.local/share/xorg/ directory.

    Old behavior can be restored through Xorg.wrap config file.
    See Xorg.wrap man page (man xorg.wrap).
( 62/111) installing xorg-util-macros                                               [################################################] 100%
( 63/111) installing xorg-server-devel                                              [################################################] 100%
( 64/111) installing xorg-server-xephyr                                             [################################################] 100%
( 65/111) installing xorg-server-xnest                                              [################################################] 100%
( 66/111) installing libsm                                                          [################################################] 100%
( 67/111) installing libxt                                                          [################################################] 100%
( 68/111) installing libxmu                                                         [################################################] 100%
( 69/111) installing xorg-xauth                                                     [################################################] 100%
( 70/111) installing xorg-server-xvfb                                               [################################################] 100%
( 71/111) installing xorg-sessreg                                                   [################################################] 100%
( 72/111) installing xorg-smproxy                                                   [################################################] 100%
( 73/111) installing xorg-x11perf                                                   [################################################] 100%
( 74/111) installing xorg-xbacklight                                                [################################################] 100%
( 75/111) installing xorg-xcmsdb                                                    [################################################] 100%
( 76/111) installing libxcursor                                                     [################################################] 100%
( 77/111) installing xorg-xcursorgen                                                [################################################] 100%
( 78/111) installing libxtst                                                        [################################################] 100%
( 79/111) installing libxcomposite                                                  [################################################] 100%
( 80/111) installing xorg-xdpyinfo                                                  [################################################] 100%
( 81/111) installing xorg-xdriinfo                                                  [################################################] 100%
( 82/111) installing xorg-xev                                                       [################################################] 100%
( 83/111) installing xorg-xgamma                                                    [################################################] 100%
( 84/111) installing xorg-xhost                                                     [################################################] 100%
( 85/111) installing xorg-xrandr                                                    [################################################] 100%
( 86/111) installing xorg-xinput                                                    [################################################] 100%
( 87/111) installing xorg-xkbevd                                                    [################################################] 100%
( 88/111) installing libxpm                                                         [################################################] 100%
( 89/111) installing libxaw                                                         [################################################] 100%
( 90/111) installing xorg-xkbutils                                                  [################################################] 100%
( 91/111) installing xorg-xkill                                                     [################################################] 100%
( 92/111) installing xorg-xlsatoms                                                  [################################################] 100%
( 93/111) installing xorg-xlsclients                                                [################################################] 100%
( 94/111) installing xorg-xmodmap                                                   [################################################] 100%
( 95/111) installing xorg-xpr                                                       [################################################] 100%
( 96/111) installing xorg-xprop                                                     [################################################] 100%
( 97/111) installing xorg-xrdb                                                      [################################################] 100%
Optional dependencies for xorg-xrdb
    gcc: for preprocessing
    mcpp: a lightweight alternative for preprocessing
( 98/111) installing xorg-xrefresh                                                  [################################################] 100%
( 99/111) installing xorg-xset                                                      [################################################] 100%
(100/111) installing xorg-xsetroot                                                  [################################################] 100%
(101/111) installing xorg-xvinfo                                                    [################################################] 100%
(102/111) installing libei                                                          [################################################] 100%
(103/111) installing xorg-xwayland                                                  [################################################] 100%
(104/111) installing xorg-xwd                                                       [################################################] 100%
(105/111) installing xorg-xwininfo                                                  [################################################] 100%
(106/111) installing xorg-xwud                                                      [################################################] 100%
(107/111) installing xorg-xinit                                                     [################################################] 100%
Optional dependencies for xorg-xinit
    xorg-twm
    xterm [pending]
(108/111) installing libutempter                                                    [################################################] 100%
(109/111) installing luit                                                           [################################################] 100%
(110/111) installing xbitmaps                                                       [################################################] 100%
(111/111) installing xterm                                                          [################################################] 100%
Optional dependencies for xterm
    xorg-mkfontscale: font scaling [installed]
:: Running post-transaction hooks...
(1/8) Reloading system manager configuration...
(2/8) Updating udev hardware database...
(3/8) Creating temporary files...
(4/8) Reloading device manager configuration...
(5/8) Arming ConditionNeedsUpdate...
(6/8) Checking for old perl modules...
(7/8) Updating fontconfig cache...
(8/8) Updating X fontdir indices...
```

