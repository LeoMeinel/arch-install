#!/bin/sh

DISK1="vda"
DISK2="vdb"
KEYMAP="de-latin1"

loadkeys "$KEYMAP"
timedatectl set-ntp true
sgdisk -o /dev/"$DISK1"
sgdisk -o /dev/"$DISK2"
sgdisk -n 0:0:+1G -t 1:ef00 /dev/"$DISK1"
sgdisk -n 0:0:+1G -t 1:ef00 /dev/"$DISK2"
sgdisk -n 0:0:0 -t 1:fd00 /dev/"$DISK1"
sgdisk -n 0:0:0 -t 1:fd00 /dev/"$DISK2"
mdadm --misc --zero-superblock /dev/"$DISK1"2
mdadm --misc --zero-superblock /dev/"$DISK2"2
mkfs.fat -n BOOT -F32 /dev/"$DISK1"1
mkfs.fat -n BOOT -F32 /dev/"$DISK2"1
mdadm --create --verbose --level=1 --metadata=1.2 --raid-devices=2 /dev/md/md0 /dev/"$DISK1"2 /dev/"$DISK2"2
cryptsetup open --type plain -d /dev/urandom /dev/md/md0 to_be_wiped
cryptsetup close to_be_wiped
cryptsetup -y -v -h sha512 -s 512 luksFormat /dev/md/md0
cryptsetup luksOpen /dev/md/md0 md0_crypt
mkfs.btrfs -L MDCRYPT /dev/mapper/md0_crypt
mount /dev/mapper/md0_crypt /mnt
cd /mnt
btrfs subvolume create @
btrfs subvolume create @tmp
btrfs subvolume create @.snapshots
btrfs subvolume create @var
btrfs subvolume create @home
cd /
btrfs subvolume list /mnt
umount /mnt
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=256 /dev/mapper/md0_crypt /mnt
mkdir -p /mnt/boot
mkdir -p /mnt/tmp
mkdir -p /mnt/.snapshots
mkdir -p /mnt/var
mkdir -p /mnt/home
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=257 /dev/mapper/md0_crypt /mnt/tmp
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=258 /dev/mapper/md0_crypt /mnt/.snapshots
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=259 /dev/mapper/md0_crypt /mnt/var
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=260 /dev/mapper/md0_crypt /mnt/home
mount /dev/"$DISK1"1 /mnt/boot
pacman -Sy --noconfirm archlinux-keyring
pacstrap /mnt base base-devel linux linux-firmware linux-headers vim btrfs-progs intel-ucode nvidia git
genfstab -U /mnt >> /mnt/etc/fstab
cd /mnt
mkdir git
cd /mnt/git
git clone https://github.com/LeoMeinel/mdadm-encrypted-btrfs.git
chmod +x /mnt/git/mdadm-encrypted-btrfs/setup.sh
chmod +x /mnt/git/mdadm-encrypted-btrfs/sysuser-setup.sh
cd /
