# mdadm-encrypted-btrfs

Arch Linux Installation using mdadm RAID1, LUKS encryption and btrfs

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

=> Use `<...>.sh |& tee <logfile>.log` to create a log file.

## Post Installation

Log into sysuser account and run

```
~/post-install.sh
reboot
```

## After starting into Desktopenvironment
If you have an NVIDIA GPU, log into all other accounts and run

```
~/nvidia-install.sh
```

Set `chrome://flags/#extension-mime-request-handling` in `ungoogled-chromium` to `Always prompt for install`

=> Reboot now

## Information

This script will only work on a system with exactly 2 disks attached. The disks have to be exactly the same size!

All data on both disks will be wiped!
