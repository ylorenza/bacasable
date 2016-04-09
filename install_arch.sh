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
# mkfs.ext4 /dev/sda1

# mount all the new part to /mnt
#mount /dev/sda1 /mnt

# install base package
# pacstrap /mnt base base-devel

# fstab
#genfstab -U /mnt >> /mnt/etc/fstab

# local
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "fr_FR.UTF-8 UTF-8" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

# keyboard layout
echo "KEYMAP=fr-pc" > /mnt/etc/vconsole.conf

# Timezone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc --utc

exit 0
