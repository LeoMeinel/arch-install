#!/bin/sh

set -e
cd
mkdir ~/git
cd ~/git
git clone https://aur.archlinux.org/paru.git
cd ~/git/paru
rustup default stable
makepkg -si --noprogressbar --noconfirm --needed
cd ~/git
git clone https://github.com/LeoMeinel/mdadm-encrypted-btrfs.git
mv ~/git/mdadm-encrypted-btrfs/post-install.sh ~/post-install.sh
rm -rf ~/git
chmod +x ~/post-install.sh
