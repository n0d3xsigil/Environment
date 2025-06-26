## Guide
Start by following step 1.0 through 1.4

## Console keyboard layout
We will use UK.
```shell
loadkeys uk
```

## Verify boot mode

```shell
cat /sys/firmware/efi/fw_plaform_size
64
```
Shows booted in UEFI mode with 64-bit x64 UEFI

## Connect network (Wireless)

Run `ip link` to get adapters
```shell
ip link
1: lo: <LOO
    link/
2: enp0s31f6: <NO-CA
    Link/
    altna
3: wlan0: <NO-C
    link/
```

To connect wireless follow guide here: [iwctl](https://wiki.archlinux.org/title/Iwctl)

Use `iwctl` to enter wireless configuration

then use `device list` to get a list of devices
```shell
iwctl
[iwd]# device list
...
wlan0
...
```

now we know the device name we can use `station _wlan0_ scan` to find access points.

```shell
[iwd]# station wlan0 scan
```
This won't show any results, but it will scan for AP's

Next we can perform `station _wlan0_ get-networks

```shell
[iwd]# station wlan0 get-networks
[list of networks]
```

The beauty of iwd is that you can tab to autocompleted. Which is great for my SSID that is randomly generated!

To connect to the AP just `station _wlan0_ connect %SSID%`

```shell
[iwd]# station wlan0 connect [redacted]
Type the network passphrase for [redacted] psk.
Passphrase: *********************************
[iwd]# quit
```

For the purpose of setup we can leave it here and go back to setup.

perform a ping test to a host of your choice, I'm using `archlinux.org` partly because thats the recommendation, but also, I want to make sure I can reach the archlinux infrastructure.

```shell
ping -3 -c 4 archlinux.org
64 bytes ...
64 bytes ...
64 bytes ...
64 bytes ...

---
4 packets
rtt min
```

Great, we have a connection. 

## update the clock
We use `timedatectl` to ensure the clock is sync'd

```shell
timedatectl
              local time:
          universal time:
                RTC time:
               Time Zone:
System clock sychronized: yes
             NTP service: active
         RTC in local TZ:
```

Great, Moving on...

## Partitioning Disks
Okay this will be fun, its a first for me. My laptop has RAID 0 across 2 1tb ssd's. 

The documentation says not to use RAID mode... so not sure if I should do what I'm about to do

lsblk shows /dev/md126 and /dev/md127. md126 shows a size of 1.9T

so going with that.

```shell
cfdisk /dev/md126
```

Accept GPT is corrupt or missing, `y`.

Create new partition for EFI boot (128M) Will rebuild this later so won't remian the same.
Create new partition for Linux Swap (256Gb)
Create new partition for Linux filesystem (1.6T)

Write changes and exit








