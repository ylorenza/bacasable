#!/bin/bash
set -e

# get the script base dir
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"


function config_install_iso {

    # load fr keyboards
    loadkeys fr-pc

    # Update clock
    timedatectl set-ntp true
}


function config_and_mount_disk {

    # format sda
    dd if=/dev/zero of=/dev/nvme0n1 bs=512 count=1

    # make part with fdisk
    sfdisk /dev/nvme0n1 < ${SCRIPT_DIR}/nvme0n1.layout

    # should fail silently if first time launching the script
    cryptsetup close /dev/mapper/cryptlvm | true

    # crypt the partition for lvm and mount it
    cryptsetup luksFormat /dev/nvme0n1p2 --batch-mode < ${SCRIPT_DIR}/luks_passwd
    cryptsetup open /dev/nvme0n1p2 cryptlvm < ${SCRIPT_DIR}/luks_passwd

    # Lvm part
    pvcreate /dev/mapper/cryptlvm
    vgcreate myVolGroup /dev/mapper/cryptlvm

    lvcreate -L 30G myVolGroup -n root
    lvcreate -L 20G myVolGroup -n var
    lvcreate -L 150G myVolGroup -n home
    lvcreate -L 20G myVolGroup -n swap

    # Format the new partition from lvm
    mkfs.ext4 /dev/myVolGroup/root
    mkfs.ext4 /dev/myVolGroup/var
    mkfs.ext4 /dev/myVolGroup/home
    mkswap /dev/myVolGroup/swap

    # mount /
    mount /dev/myVolGroup/root /mnt

    mkdir /mnt/home
    mkdir /mnt/var

    # Mount /var /home and the swap
    mount /dev/myVolGroup/var /mnt/var
    mount /dev/myVolGroup/home /mnt/home
    swapon /dev/myVolGroup/swap

    # prepare /boot
    mkfs.fat -F32 /dev/nvme0n1p1
    mkdir /mnt/boot

    mount /dev/nvme0n1p1 /mnt/boot
}


function install_base_arch {

    # install base package
    pacstrap /mnt base linux linux-firmware lvm2

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
    echo "ylicarbon" > /mnt/etc/hostname
    echo "127.0.0.1	localhost" >> /mnt/etc/hosts
    echo "::1		localhost" >> /mnt/etc/hosts
    echo "127.0.1.1	ylicarbon.localdomain	ylicarbon" >> /mnt/etc/hosts




    # grub
    arch-chroot /mnt pacman -S --noconfirm grub
    arch-chroot /mnt grub-install /dev/sda
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}


function finish_install {
    umount -R /mnt
    reboot
}


config_install_iso

config_and_mount_disk

install_base_arch

#finish_install

exit 0
