Once arch is built, you'll need to log in and get a few things up and running...

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



