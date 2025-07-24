Once arch is built, you'll need to log in and get a few things up and running...

## Pending updates
- [ ] Configure keyboard layout within x
- [ ] Configure 4k output.

## Contents
- [Network connectivity](#network-connectivity)
- [Secure boot](#secure-boot)
- [Create user](#create-user)
- [Enable Sudo](#enable-sudo)
- [Disable root](#disable-root)
- [Configure firewall](#configure-firewall)
- [nvidia hell](#nvidia-hell)
- [Enable LightDM](#enable-lightdm)
- [Enable Openbox](#enable-openbox)
  - [Configure Keyboard](#configure-keyboard)

  
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


## Enable LightDM

First step is to enable `LightDM`

```shell
[archibold@archibold ~]$ sudo systemctl enable --now lightdm
[sudo] password for archibold:    tired
Created symlink '/etc/systemd/system/display-manager.service' → '/usr/lib/systemd/system/lightdm.service'.
```


## Enable Openbox

We need to ensure **Openbox** starts after reboot

```shell
[archibold@archibold ~]$ echo "exec openbox-session" > ~/.xsession | cat ~/.xsession
exec openbox-session
```


Reboot and check

```shell
[archibold@archibold ~]$ sudo reboot
[sudo] password for archibold:    qwertyuiop

Broadcast message from root@archibold on pts/1 (Tue 2025-07-22 21:51:44 BST):

The system will reboot now!
```


### Configure Keyboard

Create the `00-keyboard.conf` file/

```bash
[archibold@archibold ~]$ sudo vim /etc/X11/xorg.conf.d/00-keyboard.conf
[sudo] password for archibold:
```



Enter the following information. Press `i` to enter _Insert_ mode.

```ini
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "gb"
EndSection
```



Press `Esc` to leave _Insert_ mode and type `:x` to save and exit. Cat the file to validate the data was saved

```bash
[archibold@archibold ~]$ cat /etc/X11/xorg.conf.d/00-keyboard.conf 
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "gb"
EndSection
```


Although this should be sufficient, we can also issue the `setxkbmap` command, so I'm going to include that in the `openbox` startup to make sure it's always applied.

```bash
[archibold@archibold ~]$ vim ~/.config/openbox/autostart
```



Insert (`i`) the following line at the top of the file

```ini
# Keyboard layout
setxkbmap gb &
```



Tap `Esc` and type `:x` to save and exit. Again, we can cat the file to ensure it was written correctly.

```bash
[archibold@archibold ~]$ cat ~/.config/openbox/autostart 
# Keyboard layout
setxkbmap gb &

# Applications
virt-manager &
```









Reconnect

```PowerShell
PS C:\Users\UserID> ssh archibold@192.168.1.21
archibold@192.168.1.21's password:   oMyGodNotAgain!
Last login: Tue Jul 22 21:34:36 2025 from 192.168.1.22
[archibold@archibold ~]$
```

