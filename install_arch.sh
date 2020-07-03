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

    DISK_PATH="/dev/nvme0n1"
    DISK_PART_EFI="/dev/nvme0n1p1"
    DISK_PART_LVM="/dev/nvme0n1p2"

    LVM_MAPPER="/dev/mapper/cryptlvm"

    VG_NAME="myVolGroup"
    LV_ROOT_NAME="root"
    LV_VAR_NAME="var"
    LV_HOME_NAME="home"
    LV_SWAP_NAME="swap"

    LV_ROOT_PATH="/dev/${VG_NAME}/${LV_ROOT_NAME}"
    LV_VAR_PATH="/dev/${VG_NAME}/${LV_VAR_NAME}"
    LV_HOME_PATH="/dev/${VG_NAME}/${LV_HOME_NAME}"
    LV_SWAP_PATH="/dev/${VG_NAME}/${LV_SWAP_NAME}"

    # format sda
    dd if=/dev/zero of=${DISK_PATH} bs=512 count=1

   # should fail silently if first time launching the script
    #cryptsetup close ${LVM_MAPPER} | true

    # make part with fdisk
    sfdisk ${DISK_PATH} < ${SCRIPT_DIR}/nvme0n1.layout

    # crypt the partition for lvm and mount it
    cryptsetup luksFormat ${DISK_PART_LVM} --batch-mode < ${SCRIPT_DIR}/luks_passwd
    cryptsetup open ${DISK_PART_LVM} < ${SCRIPT_DIR}/luks_passwd

    # Lvm part
    pvcreate ${LVM_MAPPER}
    vgcreate ${VG_NAME} ${LVM_MAPPER}

    lvcreate -L 30G ${VG_NAME} -n ${LV_ROOT_NAME}
    lvcreate -L 20G ${VG_NAME} -n ${LV_VAR_NAME}
    lvcreate -L 150G ${VG_NAME} -n ${LV_HOME_NAME}
    lvcreate -L 20G ${VG_NAME} -n ${LV_SWAP_NAME}

    # Format the new partition from lvm
    mkfs.ext4 ${LV_ROOT_PATH}
    mkfs.ext4 ${LV_VAR_PATH}
    mkfs.ext4 ${LV_HOME_PATH}
    mkswap ${LV_SWAP_PATH}

    # mount /
    mount ${LV_ROOT_PATH} /mnt

    mkdir /mnt/home
    mkdir /mnt/var

    # Mount /var /home and the swap
    mount ${LV_VAR_PATH} /mnt/var
    mount ${LV_HOME_PATH} /mnt/home
    swapon ${LV_SWAP_PATH}

    # prepare /boot
    mkfs.fat -F32 ${DISK_PART_EFI}
    mkdir /mnt/boot

    mount ${DISK_PART_EFI} /mnt/boot
}


function install_base_arch {

    # install base package
    pacstrap /mnt base linux linux-firmware lvm2 vim

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

}


function finish_install {
    umount -R /mnt
    reboot
}


config_install_iso

config_and_mount_disk

#install_base_arch

#finish_install

exit 0
