Once arch is built, you'll need to log in and get a few things up and running...

## Contents
- [Network connectivity](#network-connectivity)
- [Secure boot](#secure-boot)
- [Create user](#create-user)
- [Enable Sudo](#enable-sudo)
- [Disable root](#disable-root)
- [nvidia hell](#nvidia-hell)
- [i3 WM](#i3-wm)

  
## Network connectivity
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
New password:
Retype new password:
passwd: password updated successfully
```

## Enable Sudo
Sudo alows us to perform user substitution or to escilate our privileges, lets get it installed

```sudo
[root@archibold ~]# pacman -S sudo
resolving dependencies...
looking for conflicting packages...

Packages (1) sudo-1.9.16.p2-2

Total Download Size:   1.88 MiB
Total Installed Size:  7.76 MiB

:: Proceed with installation? [Y/n] y
:: Retrieving packages...
 sudo-1.9.16.p2-2-x86_64                               1923.0 KiB  6.76 MiB/s 00:00 [################################################] 100%
(1/1) checking keys in keyring                                                      [################################################] 100%
(1/1) checking package integrity                                                    [################################################] 100%
(1/1) loading package files                                                         [################################################] 100%
(1/1) checking for file conflicts                                                   [################################################] 100%
(1/1) checking available disk space                                                 [################################################] 100%
:: Processing package changes...
(1/1) installing sudo                                                               [################################################] 100%
:: Running post-transaction hooks...
(1/3) Reloading system manager configuration...
(2/3) Creating temporary files...
(3/3) Arming ConditionNeedsUpdate...
```

Next we need to allow are new user access to run sudo

```shell
[root@archibold ~]# EDITOR=vim visudo
```

Add ``%USER% ALL=(ALL:ALL) ALL`.

We can now logout and log back in with the new user.


## Disable root
First we need to change the `root` password by using `passwd`

```shell
[root@archibold ~]# passwd
New password:         XQQ8Si8Fa7keig
Retype new password:  XQQ8Si8Fa7keig
passwd: password updated successfully
```

Clearly `XQQ8Si8Fa7keig` is an example and not a real password.

Next we want to lock root so it can't be accessed or bruteforced.

```shell
[archibold@archibold ~]$ sudo passwd -l root
[sudo] password for archibold:
passwd: password changed.
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



```shell
[archibold@archibold ~]$ sudo pacman -S nvidia nvidia-utils lib32-nvidia-utils mesa lib32-mesa xf86-video-intel vulkan-intel vulkan-icd-loader mesa-demos mesa-utils
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

Packages (78) default-cursors-3-1  egl-gbm-1.1.2.1-1  egl-wayland-4:1.1.19-1  egl-x11-1.0.2-1  eglexternalplatform-1.2.1-1
              lib32-brotli-1.1.0-1  lib32-bzip2-1.0.8-4  lib32-curl-8.14.1-1  lib32-e2fsprogs-1.47.2-1  lib32-expat-2.7.1-1
              lib32-gcc-libs-15.1.1+r7+gf36ec88aa85a-1  lib32-glibc-2.41+r48+g5cb575ca9a3d-1  lib32-icu-76.1-1  lib32-json-c-0.18-2
              lib32-keyutils-1.6.3-2  lib32-krb5-1.21.3-1  lib32-libdrm-2.4.125-1  lib32-libelf-0.193-1  lib32-libffi-3.5.0-1
              lib32-libglvnd-1.7.0-1  lib32-libidn2-2.3.7-1  lib32-libldap-2.6.10-1  lib32-libnghttp2-1.66.0-1  lib32-libnghttp3-1.10.1-1
              lib32-libpciaccess-0.18.1-1  lib32-libpsl-0.21.5-1  lib32-libssh2-1.11.1-1  lib32-libunistring-1.3-1  lib32-libx11-1.8.12-1
              lib32-libxau-1.0.11-2  lib32-libxcb-1.17.0-1  lib32-libxcrypt-4.4.38-1  lib32-libxdmcp-1.1.5-1  lib32-libxext-1.3.6-1
              lib32-libxml2-2.14.4-2  lib32-libxshmfence-1.3.3-1  lib32-libxxf86vm-1.1.5-2  lib32-llvm-libs-1:20.1.6-1
              lib32-lm_sensors-1:3.6.2-2  lib32-ncurses-6.5-2  lib32-openssl-1:3.5.0-1  lib32-spirv-tools-1:1.4.313.0-1
              lib32-wayland-1.23.1-1  lib32-xz-5.8.1-1  lib32-zlib-1.3.1-2  lib32-zstd-1.5.7-2  libdrm-2.4.125-1  libglvnd-1.7.0-3
              libpciaccess-0.18.1-2  libx11-1.8.12-1  libxau-1.0.12-1  libxcb-1.17.0-1  libxdamage-1.1.6-2  libxdmcp-1.1.5-1
              libxext-1.3.6-1  libxfixes-6.0.1-2  libxrender-0.9.12-1  libxshmfence-1.3.3-1  libxv-1.0.13-1  libxvmc-1.0.14-1
              libxxf86vm-1.1.6-1  llvm-libs-20.1.6-3  lm_sensors-1:3.6.2-1  pixman-0.46.2-1  spirv-tools-1:1.4.313.0-1  wayland-1.23.1-2
              xcb-proto-1.17.0-3  xcb-util-0.4.1-2  xcb-util-keysyms-0.4.1-5  xorgproto-2024.1-2  lib32-mesa-1:25.1.4-1
              lib32-nvidia-utils-575.64-2  mesa-1:25.1.4-1  nvidia-575.64-2  nvidia-utils-575.64-1  vulkan-icd-loader-1.4.313.0-1
              vulkan-intel-1:25.1.4-1  xf86-video-intel-1:2.99.917+939+g4a64400e-1

Total Download Size:    579.54 MiB
Total Installed Size:  1896.19 MiB

:: Proceed with installation? [Y/n] Y
:: Retrieving packages...
 lib32-nvidia-utils-575.64-2-x86_64                      51.4 MiB  6.17 MiB/s 00:08 [################################################] 100%
 lib32-llvm-libs-1:20.1.6-1-x86_64                       42.4 MiB  2.67 MiB/s 00:16 [################################################] 100%
 nvidia-575.64-2-x86_64                                  84.6 MiB  4.79 MiB/s 00:18 [################################################] 100%
 llvm-libs-20.1.6-3-x86_64                               37.8 MiB  2.12 MiB/s 00:18 [################################################] 100%
 lib32-gcc-libs-15.1.1+r7+gf36ec88aa85a-1-x86_64         31.8 MiB  2.34 MiB/s 00:14 [################################################] 100%
 lib32-icu-76.1-1-x86_64                                 10.6 MiB  1606 KiB/s 00:07 [################################################] 100%
 lib32-mesa-1:25.1.4-1-x86_64                            10.3 MiB  1852 KiB/s 00:06 [################################################] 100%
 mesa-1:25.1.4-1-x86_64                                  10.2 MiB  1698 KiB/s 00:06 [################################################] 100%
 vulkan-intel-1:25.1.4-1-x86_64                           4.3 MiB  2.27 MiB/s 00:02 [################################################] 100%
 lib32-glibc-2.41+r48+g5cb575ca9a3d-1-x86_64              3.4 MiB  1970 KiB/s 00:02 [################################################] 100%
 libx11-1.8.12-1-x86_64                                   2.0 MiB  1643 KiB/s 00:01 [################################################] 100%
 lib32-openssl-1:3.5.0-1-x86_64                        2007.6 KiB  2.29 MiB/s 00:01 [################################################] 100%
 spirv-tools-1:1.4.313.0-1-x86_64                      1769.6 KiB  2.88 MiB/s 00:01 [################################################] 100%
 lib32-spirv-tools-1:1.4.313.0-1-x86_64                1512.5 KiB  3.03 MiB/s 00:00 [################################################] 100%
 libxcb-1.17.0-1-x86_64                                 996.0 KiB  2.53 MiB/s 00:00 [################################################] 100%
 lib32-krb5-1.21.3-1-x86_64                             775.4 KiB  2.63 MiB/s 00:00 [################################################] 100%
 xf86-video-intel-1:2.99.917+939+g4a64400e-1-x86_64     726.0 KiB  2.67 MiB/s 00:00 [################################################] 100%
 lib32-libx11-1.8.12-1-x86_64                           618.9 KiB  2.46 MiB/s 00:00 [################################################] 100%
 lib32-libelf-0.193-1-x86_64                            586.4 KiB  2.78 MiB/s 00:00 [################################################] 100%
 lib32-libunistring-1.3-1-x86_64                        557.7 KiB  2.90 MiB/s 00:00 [################################################] 100%
 lib32-libxml2-2.14.4-2-x86_64                          506.4 KiB  2.86 MiB/s 00:00 [################################################] 100%
 lib32-curl-8.14.1-1-x86_64                             372.6 KiB  2.41 MiB/s 00:00 [################################################] 100%
 libdrm-2.4.125-1-x86_64                                347.7 KiB  2.26 MiB/s 00:00 [################################################] 100%
 lib32-brotli-1.1.0-1-x86_64                            340.5 KiB  2.60 MiB/s 00:00 [################################################] 100%
 libglvnd-1.7.0-3-x86_64                                326.2 KiB  2.61 MiB/s 00:00 [################################################] 100%
 lib32-zstd-1.5.7-2-x86_64                              324.4 KiB  3.30 MiB/s 00:00 [################################################] 100%
 pixman-0.46.2-1-x86_64                                 284.6 KiB  3.23 MiB/s 00:00 [################################################] 100%
 xorgproto-2024.1-2-any                                 241.2 KiB  3.23 MiB/s 00:00 [################################################] 100%
 lib32-e2fsprogs-1.47.2-1-x86_64                        222.1 KiB  2.52 MiB/s 00:00 [################################################] 100%
 lib32-ncurses-6.5-2-x86_64                             219.6 KiB  2.82 MiB/s 00:00 [################################################] 100%
 lib32-libglvnd-1.7.0-1-x86_64                          202.7 KiB  2.87 MiB/s 00:00 [################################################] 100%
 lib32-libxcb-1.17.0-1-x86_64                           196.1 KiB  2.66 MiB/s 00:00 [################################################] 100%
 lib32-libldap-2.6.10-1-x86_64                          159.9 KiB  1926 KiB/s 00:00 [################################################] 100%
 vulkan-icd-loader-1.4.313.0-1-x86_64                   142.7 KiB  1955 KiB/s 00:00 [################################################] 100%
 wayland-1.23.1-2-x86_64                                140.1 KiB  1920 KiB/s 00:00 [################################################] 100%
 lib32-libdrm-2.4.125-1-x86_64                          139.0 KiB  2.38 MiB/s 00:00 [################################################] 100%
 lm_sensors-1:3.6.2-1-x86_64                            133.6 KiB  2.46 MiB/s 00:00 [################################################] 100%
 xcb-proto-1.17.0-3-any                                 128.5 KiB  2.06 MiB/s 00:00 [################################################] 100%
 lib32-libssh2-1.11.1-1-x86_64                          114.9 KiB  2.08 MiB/s 00:00 [################################################] 100%
 libxext-1.3.6-1-x86_64                                 106.0 KiB  2.41 MiB/s 00:00 [################################################] 100%
 lib32-xz-5.8.1-1-x86_64                                104.2 KiB  2.16 MiB/s 00:00 [################################################] 100%
 lib32-expat-2.7.1-1-x86_64                              67.9 KiB  1331 KiB/s 00:00 [################################################] 100%
 lib32-libxcrypt-4.4.38-1-x86_64                         66.7 KiB  1042 KiB/s 00:00 [################################################] 100%
 lib32-libnghttp2-1.66.0-1-x86_64                        64.1 KiB   737 KiB/s 00:00 [################################################] 100%
 lib32-libpsl-0.21.5-1-x86_64                            55.5 KiB   703 KiB/s 00:00 [################################################] 100%
 lib32-libnghttp3-1.10.1-1-x86_64                        64.2 KiB   636 KiB/s 00:00 [################################################] 100%
 lib32-libidn2-2.3.7-1-x86_64                            54.3 KiB  2.21 MiB/s 00:00 [################################################] 100%
 lib32-wayland-1.23.1-1-x86_64                           53.3 KiB  3.47 MiB/s 00:00 [################################################] 100%
 lib32-zlib-1.3.1-2-x86_64                               47.2 KiB  2.30 MiB/s 00:00 [################################################] 100%
 egl-x11-1.0.2-1-x86_64                                  37.8 KiB  1455 KiB/s 00:00 [################################################] 100%
 egl-wayland-4:1.1.19-1-x86_64                           36.8 KiB   837 KiB/s 00:00 [################################################] 100%
 lib32-json-c-0.18-2-x86_64                              35.6 KiB  1271 KiB/s 00:00 [################################################] 100%
 libxv-1.0.13-1-x86_64                                   34.9 KiB  1248 KiB/s 00:00 [################################################] 100%
 lib32-bzip2-1.0.8-4-x86_64                              32.4 KiB   926 KiB/s 00:00 [################################################] 100%
 libxrender-0.9.12-1-x86_64                              29.4 KiB   839 KiB/s 00:00 [################################################] 100%
 lib32-libxext-1.3.6-1-x86_64                            28.9 KiB   876 KiB/s 00:00 [################################################] 100%
 libxdmcp-1.1.5-1-x86_64                                 27.1 KiB   774 KiB/s 00:00 [################################################] 100%
 libxvmc-1.0.14-1-x86_64                                 24.0 KiB   558 KiB/s 00:00 [################################################] 100%
 lib32-lm_sensors-1:3.6.2-2-x86_64                       22.8 KiB   691 KiB/s 00:00 [################################################] 100%
 libpciaccess-0.18.1-2-x86_64                            21.5 KiB   653 KiB/s 00:00 [################################################] 100%
 lib32-libpciaccess-0.18.1-1-x86_64                      18.9 KiB   555 KiB/s 00:00 [################################################] 100%
 lib32-libffi-3.5.0-1-x86_64                             18.8 KiB   724 KiB/s 00:00 [################################################] 100%
 libxxf86vm-1.1.6-1-x86_64                               15.5 KiB  1106 KiB/s 00:00 [################################################] 100%
 libxfixes-6.0.1-2-x86_64                                13.6 KiB   681 KiB/s 00:00 [################################################] 100%
 egl-gbm-1.1.2.1-1-x86_64                                12.6 KiB   631 KiB/s 00:00 [################################################] 100%
 xcb-util-0.4.1-2-x86_64                                 11.6 KiB   582 KiB/s 00:00 [################################################] 100%
 libxau-1.0.12-1-x86_64                                  11.4 KiB   541 KiB/s 00:00 [################################################] 100%
 lib32-libxdmcp-1.1.5-1-x86_64                           10.3 KiB   412 KiB/s 00:00 [################################################] 100%
 lib32-libxxf86vm-1.1.5-2-x86_64                          9.2 KiB   384 KiB/s 00:00 [################################################] 100%
 lib32-keyutils-1.6.3-2-x86_64                            8.7 KiB   362 KiB/s 00:00 [################################################] 100%
 xcb-util-keysyms-0.4.1-5-x86_64                          7.5 KiB   260 KiB/s 00:00 [################################################] 100%
 eglexternalplatform-1.2.1-1-any                          7.5 KiB   535 KiB/s 00:00 [################################################] 100%
 libxdamage-1.1.6-2-x86_64                                7.1 KiB   510 KiB/s 00:00 [################################################] 100%
 lib32-libxau-1.0.11-2-x86_64                             6.8 KiB   206 KiB/s 00:00 [################################################] 100%
 libxshmfence-1.3.3-1-x86_64                              6.0 KiB   239 KiB/s 00:00 [################################################] 100%
 lib32-libxshmfence-1.3.3-1-x86_64                        5.1 KiB   214 KiB/s 00:00 [################################################] 100%
 default-cursors-3-1-any                                  2.3 KiB  92.7 KiB/s 00:00 [################################################] 100%
 nvidia-utils-575.64-1-x86_64                           275.9 MiB  7.72 MiB/s 00:36 [################################################] 100%
 Total (78/78)                                          579.5 MiB  16.2 MiB/s 00:36 [################################################] 100%
(78/78) checking keys in keyring                                                    [################################################] 100%
(78/78) checking package integrity                                                  [################################################] 100%
(78/78) loading package files                                                       [################################################] 100%
(78/78) checking for file conflicts                                                 [################################################] 100%
(78/78) checking available disk space                                               [################################################] 100%
:: Processing package changes...
( 1/78) installing xcb-proto                                                        [################################################] 100%
( 2/78) installing xorgproto                                                        [################################################] 100%
( 3/78) installing libxdmcp                                                         [################################################] 100%
( 4/78) installing libxau                                                           [################################################] 100%
( 5/78) installing libxcb                                                           [################################################] 100%
( 6/78) installing libx11                                                           [################################################] 100%
( 7/78) installing libxext                                                          [################################################] 100%
( 8/78) installing libpciaccess                                                     [################################################] 100%
( 9/78) installing libdrm                                                           [################################################] 100%
Optional dependencies for libdrm
    cairo: needed for modetest tool
(10/78) installing libxshmfence                                                     [################################################] 100%
(11/78) installing libxxf86vm                                                       [################################################] 100%
(12/78) installing llvm-libs                                                        [################################################] 100%
(13/78) installing lm_sensors                                                       [################################################] 100%
Optional dependencies for lm_sensors
    rrdtool: for logging with sensord
    perl: for sensor detection and configuration convert
(14/78) installing spirv-tools                                                      [################################################] 100%
(15/78) installing default-cursors                                                  [################################################] 100%
Optional dependencies for default-cursors
    adwaita-cursors: default cursor theme
(16/78) installing wayland                                                          [################################################] 100%
(17/78) installing mesa                                                             [################################################] 100%
Optional dependencies for mesa
    opengl-man-pages: for the OpenGL API man pages
(18/78) installing libglvnd                                                         [################################################] 100%
(19/78) installing eglexternalplatform                                              [################################################] 100%
(20/78) installing egl-wayland                                                      [################################################] 100%
(21/78) installing egl-gbm                                                          [################################################] 100%
(22/78) installing egl-x11                                                          [################################################] 100%
(23/78) installing nvidia-utils                                                     [################################################] 100%
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
(24/78) installing nvidia                                                           [################################################] 100%
(25/78) installing lib32-glibc                                                      [################################################] 100%
(26/78) installing lib32-zlib                                                       [################################################] 100%
(27/78) installing lib32-gcc-libs                                                   [################################################] 100%
(28/78) installing lib32-libxdmcp                                                   [################################################] 100%
(29/78) installing lib32-libxau                                                     [################################################] 100%
(30/78) installing lib32-libxcb                                                     [################################################] 100%
(31/78) installing lib32-libx11                                                     [################################################] 100%
(32/78) installing lib32-libxext                                                    [################################################] 100%
(33/78) installing lib32-expat                                                      [################################################] 100%
(34/78) installing lib32-libpciaccess                                               [################################################] 100%
(35/78) installing lib32-libdrm                                                     [################################################] 100%
(36/78) installing lib32-bzip2                                                      [################################################] 100%
(37/78) installing lib32-brotli                                                     [################################################] 100%
(38/78) installing lib32-e2fsprogs                                                  [################################################] 100%
(39/78) installing lib32-keyutils                                                   [################################################] 100%
(40/78) installing lib32-openssl                                                    [################################################] 100%
Optional dependencies for lib32-openssl
    ca-certificates [installed]
(41/78) installing lib32-libxcrypt                                                  [################################################] 100%
(42/78) installing lib32-libldap                                                    [################################################] 100%
(43/78) installing lib32-krb5                                                       [################################################] 100%
(44/78) installing lib32-libunistring                                               [################################################] 100%
(45/78) installing lib32-libidn2                                                    [################################################] 100%
(46/78) installing lib32-libnghttp2                                                 [################################################] 100%
(47/78) installing lib32-libnghttp3                                                 [################################################] 100%
(48/78) installing lib32-libpsl                                                     [################################################] 100%
(49/78) installing lib32-libssh2                                                    [################################################] 100%
(50/78) installing lib32-zstd                                                       [################################################] 100%
(51/78) installing lib32-curl                                                       [################################################] 100%
(52/78) installing lib32-json-c                                                     [################################################] 100%
(53/78) installing lib32-xz                                                         [################################################] 100%
(54/78) installing lib32-libelf                                                     [################################################] 100%
(55/78) installing lib32-libxshmfence                                               [################################################] 100%
(56/78) installing lib32-libxxf86vm                                                 [################################################] 100%
(57/78) installing lib32-libffi                                                     [################################################] 100%
(58/78) installing lib32-ncurses                                                    [################################################] 100%
(59/78) installing lib32-icu                                                        [################################################] 100%
(60/78) installing lib32-libxml2                                                    [################################################] 100%
(61/78) installing lib32-llvm-libs                                                  [################################################] 100%
(62/78) installing lib32-lm_sensors                                                 [################################################] 100%
(63/78) installing lib32-spirv-tools                                                [################################################] 100%
(64/78) installing lib32-wayland                                                    [################################################] 100%
(65/78) installing lib32-mesa                                                       [################################################] 100%
Optional dependencies for lib32-mesa
    opengl-man-pages: for the OpenGL API man pages
(66/78) installing lib32-libglvnd                                                   [################################################] 100%
(67/78) installing lib32-nvidia-utils                                               [################################################] 100%
Optional dependencies for lib32-nvidia-utils
    lib32-opencl-nvidia
(68/78) installing libxv                                                            [################################################] 100%
(69/78) installing libxvmc                                                          [################################################] 100%
(70/78) installing pixman                                                           [################################################] 100%
(71/78) installing xcb-util                                                         [################################################] 100%
(72/78) installing libxfixes                                                        [################################################] 100%
(73/78) installing libxrender                                                       [################################################] 100%
(74/78) installing libxdamage                                                       [################################################] 100%
(75/78) installing xf86-video-intel                                                 [################################################] 100%
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
    libxrandr: for intel-virtual-output
    libxinerama: for intel-virtual-output
    libxcursor: for intel-virtual-output
    libxtst: for intel-virtual-output
    libxss: for intel-virtual-output
(76/78) installing vulkan-icd-loader                                                [################################################] 100%
Optional dependencies for vulkan-icd-loader
    vulkan-driver: packaged vulkan driver [installed]
(77/78) installing xcb-util-keysyms                                                 [################################################] 100%
(78/78) installing vulkan-intel                                                     [################################################] 100%
Optional dependencies for vulkan-intel
    vulkan-mesa-layers: additional vulkan layers
:: Running post-transaction hooks...
(1/7) Creating system user accounts...
Creating group 'nvidia-persistenced' with GID 143.
Creating user 'nvidia-persistenced' (NVIDIA Persistence Daemon) with UID 143 and GID 143.
(2/7) Reloading system manager configuration...
(3/7) Reloading device manager configuration...
(4/7) Arming ConditionNeedsUpdate...
(5/7) Updating module dependencies...
(6/7) Updating linux initcpios...
==> Building image from preset: /etc/mkinitcpio.d/linux.preset: 'default'
==> Using configuration file: '/etc/mkinitcpio.conf'
  -> -k /boot/vmlinuz-linux -c /etc/mkinitcpio.conf -U /boot/EFI/Linux/archibold.efi
==> Starting build: '6.15.3-arch1-1'
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
(7/7) Reloading system bus configuration...
```

That is 2G storage gone.


Mext we need to incorporate the nvidia_drm module

```shell
[archibold@archibold ~]$ echo "$(cat /etc/kernel/cmdline) nvidia_drm.modeset=1" | sudo tee /etc/kernel/cmdline
[sudo] password for archibold:
root=PARTUUID=75bd02ea-c59a-45be-8b64-e38e088c68ba rw quiet loglevel=3 nvidia_drm.modeset=1
```

Lets rebuild the UKI again...

```shell
[archibold@archibold ~]$ sudo mkinitcpio -p linux
==> Building image from preset: /etc/mkinitcpio.d/linux.preset: 'default'
==> Using configuration file: '/etc/mkinitcpio.conf'
  -> -k /boot/vmlinuz-linux -c /etc/mkinitcpio.conf -U /boot/EFI/Linux/archibold.efi
==> Starting build: '6.15.3-arch1-1'
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

Reboot, log in and check lsmod for issues

```shell
[archibold@archibold ~]$ lsmod | grep nvidia
nvidia_drm            143360  0
nvidia_uvm           3874816  0
nvidia_modeset       1843200  1 nvidia_drm
drm_ttm_helper         16384  2 nvidia_drm,xe
video                  81920  3 xe,i915,nvidia_modeset
nvidia              112238592  3 nvidia_uvm,nvidia_drm,nvidia_modeset
```

Check to see if the GPU is visable

```
[archibold@archibold ~]$ nvidia-smi
Thu Jun 26 18:45:25 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 575.64                 Driver Version: 575.64         CUDA Version: 12.9     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA RTX A2000 Laptop GPU    Off |   00000000:01:00.0 Off |                  N/A |
| N/A   46C    P0              9W /   40W |       1MiB /   4096MiB |      0%      Default |
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

Check if the OpenGL renderer is working


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

