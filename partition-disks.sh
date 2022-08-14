#!/bin/sh

KEYMAP="de-latin1"
MIRRORCOUNTRIES="Netherlands,Germany"

SIZE1="$(lsblk -rno TYPE,SIZE,NAME | grep "disk" | sed 's/disk //' | grep -o '^\S*' | sed -n '1p')"
SIZE2="$(lsblk -rno TYPE,SIZE,NAME | grep "disk" | sed 's/disk //' | grep -o '^\S*' | sed -n '2p')"
if [ "$SIZE1" = "$SIZE2" ]
then
  DISK1="$(lsblk -rno TYPE,SIZE,NAME | grep "disk" | sed "s/disk //;s/$SIZE1 //" | sed -n '1p')"
  DISK2="$(lsblk -rno TYPE,SIZE,NAME | grep "disk" | sed "s/disk //;s/$SIZE2 //" | sed -n '2p')"
else
  echo "ERROR: There are not exactly 2 disks with the same size attached!"
  exit
fi
umount -AR /mnt
if lsblk -rno TYPE,NAME | grep "crypt" | sed "s/crypt //"
then
  cryptsetup luksClose "$(lsblk -rno TYPE,NAME | grep "crypt" | sed "s/crypt //")"
  if lsblk -rno TYPE,NAME | grep "raid1" | sed "s/raid1 //"
  then
    cryptsetup erase /dev/"$(lsblk -rno TYPE,NAME | grep "raid1" | sed "s/raid1 //")"
    sgdisk -Z /dev/"$(lsblk -rno TYPE,NAME | grep "raid1" | sed "s/raid1 //")"
    mdadm --stop --scan
    mdadm --zero-superblock /dev/"$DISK1"2
    mdadm --zero-superblock /dev/"$DISK2"2
  fi
  elif lsblk -rno TYPE,NAME | grep "raid1" | sed "s/raid1 //"
  then
    sgdisk -Z /dev/"$(lsblk -rno TYPE,NAME | grep "raid1" | sed "s/raid1 //")"
    mdadm --stop --scan
    mdadm --zero-superblock /dev/"$DISK1"2
    mdadm --zero-superblock /dev/"$DISK2"2
fi
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
mkdir /mnt/var
mkdir /mnt/home
mkdir /mnt/tmp
mkdir /mnt/.snapshots
mkdir /mnt/boot
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=257 /dev/mapper/md0_crypt /mnt/var
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=258 /dev/mapper/md0_crypt /mnt/home
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=259 /dev/mapper/md0_crypt /mnt/tmp
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=260 /dev/mapper/md0_crypt /mnt/.snapshots
mount /dev/"$DISK1"1 /mnt/boot
{
  echo "base"
  echo "base-devel"
  echo "linux"
  echo "linux-firmware"
  echo "linux-headers"
  echo "vim"
  echo "btrfs-progs"
  echo "git"
  echo "iptables-nft"
  echo "reflector"
  echo "mesa"
} > /root/packages.txt
sed -i 's/#Color/Color/;s/#ParallelDownloads = 5/ParallelDownloads = 10/;s/#NoProgressBar/NoProgressBar/' /etc/pacman.conf
reflector --save /etc/pacman.d/mirrorlist --country $MIRRORCOUNTRIES --protocol https --latest 10 --sort rate
pacman -Sy --noprogressbar --noconfirm archlinux-keyring lshw
if lscpu | grep "Vendor ID:" | grep -q "GenuineIntel"
then
  echo "intel-ucode" >> /root/packages.txt
fi
if lscpu | grep "Vendor ID:" | grep -q "AuthenticAMD"
then
  echo "amd-ucode" >> /root/packages.txt
fi
if lshw -C display | grep "vendor:" | grep -q "NVIDIA Corporation"
then
  {
    echo "nvidia"
    echo "nvidia-settings"
  } >> /root/packages.txt
fi
if lshw -C display | grep "vendor:" | grep -q "Advanced Micro Devices, Inc."
then
  {
    echo "xf86-video-amdgpu"
    echo "vulkan-radeon"
    echo "libva-mesa-driver"
    echo "mesa-vdpau"
  } >> /root/packages.txt
fi
if lshw -C display | grep "vendor:" | grep -q "Intel Corporation"
then
  {
    echo "xf86-video-intel"
    echo "vulkan-intel"
  } >> /root/packages.txt
fi
pacstrap /mnt - < /root/packages.txt
genfstab -U /mnt >> /mnt/etc/fstab
mkdir /mnt/git
cd /mnt/git
git clone https://github.com/LeoMeinel/mdadm-encrypted-btrfs.git
chmod +x /mnt/git/mdadm-encrypted-btrfs/setup.sh
