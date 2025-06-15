# Environment
My environment

## VPN
Open VPN. 

### Full guide
A full guide can be found on the Arch WIKI (https://wiki.archlinux.org/title/OpenVPN) so do take a look at that for more detailed process.

### Install OpenVPN
Type `sudo pacman -S openvpn`

```sh
[archibold@ARCHIBOLD ~]$ sudo pacman -S openvpn
[sudo] password for archibold:
warning: openvpn-2.6.14-1 is up to date -- reinstalling
resolving dependencies...
looking for conflicting packages...

Packages (1) openvpn-2.6.14-1

Total Installed Size:  1.69 MiB
Net Upgrade Size:      0.00 MiB

:: Proceed with installation? [Y/n] y
:: Retrieving packages...
checking keys in keyring                [##############################] 100%
checking package integrity              [##############################] 100%
loading package files                   [##############################] 100%
checking for file conflicts             [##############################] 100%
checking available disk space           [##############################] 100%
:: Processing package changes...
reinstalling openvpn                    [##############################] 100%
:: Running post-transaction hooks...
(1/5) Creating system user accounts...
(2/5) Reloading system manager configuration...
(3/5) Restarting marked services...
(4/5) Creating temporary files...
(5/5) Arming ConditionNeedsUpdate...
[archibold@ARCHIBOLD ~]$
```

### Install eOVPN
I live in the terminal but I like the convience of a GUI. So let's install eOVPN

Because eOVPN is an AUR package I want to clone into my Sources directory
```sh
cd ~/Sources/
[archibold@ARCHIBOLD ~]$ cd ~/Sources/
[archibold@ARCHIBOLD Sources]$ 
```

Next I want to clone the repository in the Sources directory
```sh
[archibold@ARCHIBOLD Sources]$ git clone https://aur.archlinux.org/eovpn.git
Cloning into 'eovpn'...
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint:
hint: 	git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint: 	git branch -m <name>
remote: Enumerating objects: 140, done.
remote: Counting objects: 100% (140/140), done.
remote: Compressing objects: 100% (110/110), done.
remote: Total 140 (delta 30), reused 140 (delta 30), pack-reused 0 (from 0)
Receiving objects: 100% (140/140), 41.58 KiB | 887.00 KiB/s, done.
Resolving deltas: 100% (30/30), done.
[archibold@ARCHIBOLD Sources]$ 
```

Next we will package the file ready for installation
```sh
[archibold@ARCHIBOLD Sources]$ cd eovpn/
[archibold@ARCHIBOLD eovpn]$ makepkg -Si
==> Making package: eovpn 1.30-3 (Fri 06 Jun 2025 15:31:13 BST)
==> Retrieving sources...
  -> Downloading 1.30.tar.gz...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100 1381k    0 1381k    0     0  1872k      0 --:--:-- --:--:-- --:--:-- 1872k
==> Validating source files with sha256sums...
    1.30.tar.gz ... Passed
==> Entering fakeroot environment...
==> Creating source package...
  -> Adding PKGBUILD...
  -> Generating .SRCINFO file...
  -> Compressing source package...
==> Leaving fakeroot environment.
==> Source package created: eovpn (Fri 06 Jun 2025 15:31:14 BST)
[archibold@ARCHIBOLD eovpn]$ 
```

Now we can go ahead and install the eOVPN package

```sh
[archibold@ARCHIBOLD eovpn]$ sudo pacman -U eovpn-1.30-3-x86_64.pkg.tar.zst 
loading packages...
resolving dependencies...
looking for conflicting packages...

Packages (1) eovpn-1.30-3

Total Installed Size:  3.58 MiB

:: Proceed with installation? [Y/n] y
(1/1) checking keys in keyring                                                                [#######################################################] 100%
(1/1) checking package integrity                                                              [#######################################################] 100%
(1/1) loading package files                                                                   [#######################################################] 100%
(1/1) checking for file conflicts                                                             [#######################################################] 100%
(1/1) checking available disk space                                                           [#######################################################] 100%
:: Processing package changes...
(1/1) installing eovpn                                                                        [#######################################################] 100%
Optional dependencies for eovpn
    openvpn3
:: Running post-transaction hooks...
(1/4) Arming ConditionNeedsUpdate...
(2/4) Compiling GSettings XML schema files...
(3/4) Updating icon theme caches...
(4/4) Updating the desktop file MIME type cache...
[archibold@ARCHIBOLD eovpn]$
```
### Configure eOVPN
#### TryHackMe
No, not a request, the site.

In this instance, I only want the one VPN. Although I do use others, just the THM VPN matters.

Firstly, navigate to https://tryhackme.com/access

I'm chossing the EU-VIP-2, no real reason.

Click Regenerate followed by Download configuration file. 





this one
that one
the other one

