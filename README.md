# mdadm-encrypted-btrfs

Arch Linux Installation using mdadm RAID1, LUKS encryption and btrfs

## Info

:information_source: | This script will only work on a system with exactly 2 disks of the same size attached!

:warning: | All data on both disks will be wiped!

## Pre-installation

:information_source: | Follow the `Pre-installation` section of this [guide](https://wiki.archlinux.org/title/Installation_guide#Pre-installation) until (including) the `Connect to the internet` section if needed.

## Installation

```
pacman -Sy git
git clone https://github.com/LeoMeinel/mdadm-encrypted-btrfs.git
chmod +x /root/mdadm-encrypted-btrfs/partition-disks.sh
/root/mdadm-encrypted-btrfs/partition-disks.sh
arch-chroot /mnt
/git/mdadm-encrypted-btrfs/setup.sh
exit
umount -AR /mnt
reboot
```

:information_source: | Use `<...>.sh |& tee <logfile>.log` to create a log file.

:information_source: | Set variables before running `partition-disks.sh` using `vim /root/.../partition-disks.sh`

:information_source: | Set variables after running `partition-disks.sh` using `nvim /git/.../setup.sh` and `nvim /git/.../post-install.sh`

### *Low GRUBRESOLUTION for VM*

:bulb: | *You should set a low GRUBRESOLUTION for Virtual Machines.*

:bulb: | *Otherwise there might be inconveniences during Post-installation.*

:bulb: | *For example "1280x720" on a "1920x1080" screen.*

## Post-installation (tty)

:information_source: | Log into sysuser account and run

```
~/post-install.sh
reboot
```

## Post-installation (DE)

### Do this for every user account

:information_source: |  Set `chrome://flags/#extension-mime-request-handling` in `ungoogled-chromium` to `Always prompt for install`

:information_source: |  Change Wallpaper by `right-clicking` your `Desktop`

### Do this additionally if if you have an NVIDIA GPU

```
~/nvidia-install.sh
```
