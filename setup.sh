#!/bin/sh

DISK1="vda"
DISK2="vdb"
SYSUSER="systux"
VIRTUSER="virt"
HOMEUSER="leo"
KEYMAP="de-latin1"
TIMEZONE="Europe/Paris"
HOSTNAME="tux-stellaris-15"
DOMAIN="meinel.dev"
MIRRORCOUNTRIES="France,Germany"
GRUBRESOLUTION="2560x1440"

pacman --noconfirm -Syu
groupadd -r sudo
groupadd -r libvirt
useradd -r -m -G sudo "$SYSUSER"
useradd -m -G libvirt "$VIRTUSER"
useradd -m "$HOMEUSER"
echo "Enter password for root"
passwd root || exit
echo "Enter password for $SYSUSER"
passwd "$SYSUSER" || exit
echo "Enter password for $VIRTUSER"
passwd "$VIRTUSER" || exit
echo "Enter password for $HOMEUSER"
passwd "$HOMEUSER" || exit
pacman -S --noprogressbar --noconfirm plasma-desktop plasma-wayland-session kgpg dolphin gwenview kalendar kmail kmix kompare ksystemlog okular print-manager spectacle bleachbit sddm sddm-kcm plasma-nm neofetch htop mpv libreoffice-still rxvt-unicode chromium zram-generator virt-manager qemu-desktop libvirt edk2-ovmf dnsmasq pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber rustup grub grub-btrfs efibootmgr mtools inetutils bluez bluez-utils cups hplip alsa-utils openssh rsync reflector acpi acpi_call tlp openbsd-netcat nss-mdns acpid ntfs-3g nvidia-settings notepadqq intellij-idea-community-edition jdk11-openjdk jdk-openjdk jdk17-openjdk mariadb sqlite screen gradle arch-audit ark noto-fonts
echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/sudo
chmod +x /git/mdadm-encrypted-btrfs/sysuser-setup.sh
su -c '/git/mdadm-encrypted-btrfs/sysuser-setup.sh' "$SYSUSER"
echo "%sudo ALL=(ALL:ALL) ALL" > /etc/sudoers.d/sudo
mkdir /etc/sddm.conf.d
{
  echo "[Theme]"
  echo "Current=Sweet"
} > /etc/sddm.conf.d/kde_settings.conf
cd / || exit
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
timedatectl set-ntp true
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen
{
  echo "--save /etc/pacman.d/mirrorlist"
  echo "--country $MIRRORCOUNTRIES"
  echo "--protocol https"
  echo "--latest 5"
  echo "--sort age"
} > /etc/xdg/reflector/reflector.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
{
  echo "127.0.0.1  localhost"
  echo "127.0.1.1  $HOSTNAME.$DOMAIN	$HOSTNAME"
  echo "::1  ip6-localhost ip6-loopback"
  echo "ff02::1  ip6-allnodes"
  echo "ff02::2  ip6-allrouters"
} > /etc/hosts
{
  echo "[zram0]"
  echo "zram-size = ram / 2"
  echo "compression-algorithm = zstd"
} > /etc/systemd/zram-generator.conf
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable avahi-daemon
systemctl enable tlp
systemctl enable reflector
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable acpid
systemctl enable nftables
systemctl enable sddm
sed -i 's/MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block mdadm_udev encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux
UUID="$(blkid -s UUID -o value /dev/md/md0)"
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=UUID=$UUID:md0_crypt root=\/dev\/mapper\/md0_crypt video=$GRUBRESOLUTION\"/" /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
cp -r /boot /boot.bak
umount /boot
mount /dev/"$DISK2"1 /boot
cp -r /boot.bak/* /boot/
umount /boot
mount /dev/"$DISK1"1 /boot
mdadm --detail --scan >> /etc/mdadm.conf
sed -i "s/name=archiso:md0 /name=$HOSTNAME:md0 /" /etc/mdadm.conf
chmod +x /git/mdadm-encrypted-btrfs/dot-files.sh
su -c '/git/mdadm-encrypted-btrfs/dot-files.sh' "$SYSUSER"
su -c '/git/mdadm-encrypted-btrfs/dot-files.sh' "$VIRTUSER"
su -c '/git/mdadm-encrypted-btrfs/dot-files.sh' "$HOMEUSER"
rm -rf /git
