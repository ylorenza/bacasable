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

        # disable beep
    if lsmod | grep "pcspkr" &> /dev/null ; then
      echo "pcspkr is loaded. Remove it"
      rmmod pcspkr
    else
      echo "pcspkr is not loaded!"
    fi

    # Update clock
    timedatectl set-ntp true
}


function config_and_mount_disk {

    # format sda
    dd if=/dev/zero of=/dev/sda bs=512 count=1

    # make part with fdisk
    sfdisk /dev/sda < ${SCRIPT_DIR}/sda.layout

    # format filesystem
    mkfs.ext4 -F /dev/sda1
    mkswap -f /dev/sda2
    mkfs.ext4 -F /dev/sda3

    # mount all the new part to /mnt
    mount /dev/sda1 /mnt && mkdir /mnt/home
    mount /dev/sda3 /mnt/home
    swapon /dev/sda2
}


function install_base_arch {

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

    # grub
    arch-chroot /mnt pacman -S --noconfirm grub
    arch-chroot /mnt grub-install /dev/sda
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}


function finish_install {
    umount -R /mnt
    reboot
}


echo "install bac_a_sable server"

config_install_iso

config_and_mount_disk

install_base_arch

# blacklist beep
echo "blacklist pcspkr" > /mnt/etc/modprobe.d/nobeep.conf

# add custom package
arch-chroot /mnt pacman -S --noconfirm glances vim openssh docker

# enable some service
arch-chroot /mnt systemctl enable dhcpcd.service
arch-chroot /mnt systemctl enable sshd.service
arch-chroot /mnt systemctl enable docker.service

finish_install

exit 0