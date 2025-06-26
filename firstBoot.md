Once arch is built, you'll need to log in and get a few things up and running...

## Contents
- [Network connectivity](#network-connectivity)
- [Secure boot](#secure-boot)
- [Create user](#create-user)
- [Enable Sudo](#enable-sudo)
- [Disable root](#disable-root)

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


