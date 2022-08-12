#!/bin/sh

DISK1="vda"
DISK2="vdb"
KEYMAP="de-latin1"
OLD_LUKS="md0_crypt"
OLD_MDADM="md0"
MIRRORCOUNTRIES="Netherlands"

umount -AR /mnt
cryptsetup luksClose "$OLD_LUKS"
cryptsetup erase /dev/md/"$OLD_MDADM"
sgdisk -Z /dev/md/"$OLD_MDADM"
mdadm --stop --scan
mdadm --zero-superblock /dev/"$DISK1"2
mdadm --zero-superblock /dev/"$DISK2"2
set -e
loadkeys "$KEYMAP"
timedatectl set-ntp true
sgdisk -Z /dev/"$DISK1"
sgdisk -Z /dev/"$DISK2"
sgdisk -n 0:0:+1G -t 1:ef00 /dev/"$DISK1"
sgdisk -n 0:0:+1G -t 1:ef00 /dev/"$DISK2"
sgdisk -n 0:0:0 -t 1:fd00 /dev/"$DISK1"
sgdisk -n 0:0:0 -t 1:fd00 /dev/"$DISK2"
mkfs.fat -n BOOT -F32 /dev/"$DISK1"1
mkfs.fat -n BOOT -F32 /dev/"$DISK2"1
mdadm --create --verbose --level=1 --metadata=1.2 --raid-devices=2 --homehost=any /dev/md/md0 /dev/"$DISK1"2 /dev/"$DISK2"2
cryptsetup open --type plain -d /dev/urandom /dev/md/md0 to_be_wiped
cryptsetup close to_be_wiped
cryptsetup -y -v -h sha512 -s 512 luksFormat /dev/md/md0
cryptsetup luksOpen /dev/md/md0 md0_crypt
mkfs.btrfs -L MDCRYPT /dev/mapper/md0_crypt
mount /dev/mapper/md0_crypt /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@snapshots
umount /mnt
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=256 /dev/mapper/md0_crypt /mnt
mkdir {/mnt/var,/mnt/home,/mnt/tmp,/mnt/.snapshots,/mnt/boot}
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=257 /dev/mapper/md0_crypt /mnt/var
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=258 /dev/mapper/md0_crypt /mnt/home
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=259 /dev/mapper/md0_crypt /mnt/tmp
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=260 /dev/mapper/md0_crypt /mnt/.snapshots
mount /dev/"$DISK1"1 /mnt/boot
sed -i 's/#Color/Color/;s/#ParallelDownloads = 5/ParallelDownloads = 10/;s/#NoProgressBar/NoProgressBar/' /etc/pacman.conf
reflector --save /etc/pacman.d/mirrorlist --country $MIRRORCOUNTRIES --protocol https --latest 5 --sort age
pacman -Sy --noprogressbar --noconfirm archlinux-keyring
pacstrap /mnt base base-devel linux linux-firmware linux-headers vim btrfs-progs intel-ucode nvidia git iptables-nft
genfstab -U /mnt >> /mnt/etc/fstab
mkdir /mnt/git
cd /mnt/git
git clone https://github.com/LeoMeinel/mdadm-encrypted-btrfs.git
chmod +x /mnt/git/mdadm-encrypted-btrfs/setup.sh
