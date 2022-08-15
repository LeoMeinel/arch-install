#!/bin/bash

KEYMAP="de-latin1"
HOSTNAME="tux-stellaris-15"
SYSUSER="systux"
VIRTUSER="virt"
HOMEUSER="leo"
GUESTUSER="guest"
TIMEZONE="Europe/Amsterdam"
DOMAIN="meinel.dev"
MIRRORCOUNTRIES="NL,DE,DK,FR"
GRUBRESOLUTION="2560x1440"

set -e
SIZE1="$(lsblk -rno TYPE,SIZE | grep "disk" | sed 's/disk//' | sed -n '1p' | tr -d "[:space:]")"
SIZE2="$(lsblk -rno TYPE,SIZE | grep "disk" | sed 's/disk//' | sed -n '2p' | tr -d "[:space:]")"
if [ "$SIZE1" = "$SIZE2" ]
then
  DISK1="$(lsblk -rnpo TYPE,NAME | grep "disk" | sed "s/disk//" | sed -n '1p' | tr -d "[:space:]")"
  DISK2="$(lsblk -rnpo TYPE,NAME | grep "disk" | sed "s/disk//" | sed -n '2p' | tr -d "[:space:]")"
else
  echo "ERROR: There are not exactly 2 disks with the same size attached!"
  exit 19
fi
read -rp "Install to $DISK1 and $DISK2? (Type 'yes' in capital letters): " choice
case "$choice" in
  YES ) echo "Installing to $DISK1 and $DISK2..."
  ;;
  * ) echo "ERROR: User aborted installing to $DISK1 and $DISK2"
  exit 125
  ;;
esac
groupadd -r sudo
groupadd -r libvirt
useradd -m -G sudo,wheel "$SYSUSER"
useradd -m -G libvirt "$VIRTUSER"
useradd -m "$HOMEUSER"
useradd -m "$GUESTUSER"
echo "Enter password for root"
passwd root
echo "Enter password for $SYSUSER"
passwd "$SYSUSER"
echo "Enter password for $VIRTUSER"
passwd "$VIRTUSER"
echo "Enter password for $HOMEUSER"
passwd "$HOMEUSER"
echo "Enter password for $GUESTUSER"
passwd "$GUESTUSER"
sed -i 's/#Color/Color/;s/#ParallelDownloads = 5/ParallelDownloads = 10/;s/#CacheDir/CacheDir/' /etc/pacman.conf
{
  echo ""
  echo "[options]"
  echo "Include = /etc/pacman.d/repo/aur.conf"
} >> /etc/pacman.conf
mkdir -p /etc/pacman.d/repo
{
  echo "[options]"
  echo "CacheDir = /var/cache/aur/pkg"
  echo ""
  echo "[aur]"
  echo "SigLevel = PackageOptional DatabaseOptional"
  echo "Server = file:///var/lib/repo/aur"
} > /etc/pacman.d/repo/aur.conf
mkdir -p /var/cache/aur/pkg
mkdir -p /var/lib/repo/aur
repo-add /var/lib/repo/aur/aur.db.tar.gz
reflector --save /etc/pacman.d/mirrorlist --country $MIRRORCOUNTRIES --protocol https --latest 20 --sort rate
pacman -Sy
pacman -S --noprogressbar --noconfirm --needed plasma-desktop plasma-wayland-session kgpg dolphin gwenview kalendar kmail kompare okular print-manager spectacle plasma-pa krunner kvantum powerdevil kinfocenter power-profiles-daemon arc-gtk-theme kde-gtk-config cantarell-fonts otf-font-awesome bleachbit sddm sddm-kcm plasma-nm ksystemlog neofetch htop mpv libreoffice-still rxvt-unicode zram-generator virt-manager qemu-desktop libvirt edk2-ovmf dnsmasq pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber rustup grub grub-btrfs efibootmgr mtools inetutils bluez bluez-utils ethtool iw cups hplip alsa-utils openssh rsync acpi acpi_call openbsd-netcat nss-mdns acpid ntfs-3g notepadqq intellij-idea-community-edition jdk17-openjdk jdk-openjdk jdk11-openjdk mariadb screen gradle arch-audit ark noto-fonts snapper lrzip lzop p7zip unarchiver unrar devtools pam-u2f lshw man-db
umount /.snapshots
rm -rf /.snapshots
sed -i 's/ALLOW_GROUPS=""/ALLOW_GROUPS="sudo"/;s/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="5"/;s/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="7"/;s/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="0"/;s/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"/' /usr/share/snapper/config-templates/default
snapper --no-dbus -c root create-config /
snapper --no-dbus -c var create-config /var
snapper --no-dbus -c home create-config /home
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a
chmod 750 /.snapshots
chmod a+rx /.snapshots
chown :sudo /.snapshots
chmod 750 /var/.snapshots
chmod a+rx /var/.snapshots
chown :sudo /var/.snapshots
chmod 750 /home/.snapshots
chmod a+rx /home/.snapshots
chown :sudo /home/.snapshots
echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/sudo
chmod +x /git/mdadm-encrypted-btrfs/sysuser-setup.sh
su -c '/git/mdadm-encrypted-btrfs/sysuser-setup.sh' "$SYSUSER"
sed -i 's/#LocalRepo/LocalRepo/;s/#Chroot/Chroot/;s/#RemoveMake/RemoveMake/;s/#CleanAfter/CleanAfter/;s/#\[bin\]/\[bin\]/;s/#FileManager = vifm/FileManager = vim/' /etc/paru.conf
echo "%sudo ALL=(ALL:ALL) ALL" > /etc/sudoers.d/sudo
mkdir /etc/sddm.conf.d
{
  echo "[Theme]"
  echo "Current=Nordic-darker"
} > /etc/sddm.conf.d/kde_settings.conf
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/;s/#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/;s/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/;s/#nl_NL.UTF-8 UTF-8/nl_NL.UTF-8 UTF-8/' /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen
{
  echo "--save /etc/pacman.d/mirrorlist"
  echo "--country $MIRRORCOUNTRIES"
  echo "--protocol https"
  echo "--latest 20"
  echo "--sort rate"
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
chmod +x /git/mdadm-encrypted-btrfs/dot-files.sh
sed -i 's/MODULES=()/MODULES=(btrfs)/;s/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block mdadm_udev encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux
UUID="$(blkid -s UUID -o value /dev/md/md0)"
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=UUID=$UUID:md0_crypt root=\/dev\/mapper\/md0_crypt video=$GRUBRESOLUTION\"/" /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
cp -r /boot /.boot.bak
umount /boot
mount "$DISK2"1 /boot
cp -r /.boot.bak/* /boot/
umount /boot
mount "$DISK1"1 /boot
mkdir -p /etc/pacman.d/hooks
{
  echo "[Trigger]"
  echo "Operation = Upgrade"
  echo "Operation = Install"
  echo "Operation = Remove"
  echo "Type = Path"
  echo "Target = usr/lib/modules/*/vmlinuz"
  echo ""
  echo "[Action]"
  echo "Depends = rsync"
  echo "Description = Backing up /boot..."
  echo "When = PreTransaction"
  echo "Exec = /usr/bin/rsync -a --delete /boot /.boot.bak"
} > /etc/pacman.d/hooks/95-bootbackup.hook
mdadm --detail --scan >> /etc/mdadm.conf
archlinux-java set java-17-openjdk
chown -R "$SYSUSER": /var/lib/repo/aur
mkdir -p /usr/share/wallpapers/Custom/content
cd /git
git clone https://github.com/LeoMeinel/wallpapers.git
mv /git/wallpapers/*.jpg /git/wallpapers/*.png /usr/share/wallpapers/Custom/content/
chmod -R 755 /usr/share/wallpapers/Custom
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable avahi-daemon
systemctl enable power-profiles-daemon
systemctl enable reflector
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable acpid
systemctl enable nftables
systemctl enable sddm
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
if pacman -Qqd | grep -q "nvidia-utils"
then
systemctl enable nvidia-resume.service
nvidia-xconfig
fi
su -c '/git/mdadm-encrypted-btrfs/dot-files.sh' "$SYSUSER"
su -c '/git/mdadm-encrypted-btrfs/dot-files.sh' "$VIRTUSER"
su -c '/git/mdadm-encrypted-btrfs/dot-files.sh' "$HOMEUSER"
su -c '/git/mdadm-encrypted-btrfs/dot-files.sh' "$GUESTUSER"
rm -rf /git
