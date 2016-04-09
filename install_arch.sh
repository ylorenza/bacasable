#!/bin/bash
set -e

echo "install bac_a_sable server"

# load fr keyboards
loadkeys fr-pc

# disable beep
if lsmod | grep "pcspkr" &> /dev/null ; then
  echo "pcspkr is loaded. Remove it"
  rmmod pcspkr
else
  echo "pcspkr is not loaded!"
fi

# Update clock
timedatectl set-ntp true

# format sda
dd if=/dev/zero of=/dev/sda bs=512 count=1

# make part with fdisk
sfdisk /dev/sda < sda.layout

# format filesystem
mkfs.ext4 -F /dev/sda1

# mount all the new part to /mnt
mount /dev/sda1 /mnt

# install base package
pacstrap /mnt base base-devel

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

# local
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "fr_FR.UTF-8 UTF-8" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

# keyboard layout
echo "KEYMAP=fr-pc" > /mnt/etc/vconsole.conf

# Timezone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot /mnt hwclock --systohc --utc

# hostname
echo "bacasable" > /mnt/etc/hostname

arch-chroot /mnt systemctl enable dhcpcd.service

arch-chroot /mnt pacman -S --noconfirm grub

arch-chroot /mnt grub-install /dev/sda

arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg


umount -R /mnt

echo "finish install of bacasable, please remove the usb key and reboot"

exit 0
