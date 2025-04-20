#!/bin/bash

set -e

DISK="/dev/sdX"  # Replace with your actual disk, e.g. /dev/sda or /dev/nvme0n1
HOST=""   #hostname
USER=""     #username
USERPASS=""	#host password
ROOTPASS=""	#root password

echo "==> Wiping and partitioning $DISK..."

# Wipe disk
sgdisk --zap-all $DISK

# Create partitions: EFI (2G), Swap (8G), Root (rest)
sgdisk -n1:0:+2G -t1:ef00 -c1:EFI $DISK
sgdisk -n2:0:+8G -t2:8200 -c2:SWAP $DISK
sgdisk -n3:0:+150G   -t3:8300 -c3:ROOT $DISK

# Wait a second for kernel to detect changes
sleep 2

EFI="${DISK}1"
SWAP="${DISK}2"
ROOT="${DISK}3"

echo "==> Formatting partitions..."

mkfs.fat -F32 $EFI
mkswap $SWAP
mkfs.ext4 $ROOT

echo "==> Mounting filesystems..."

mount $ROOT /mnt
mkdir -p /mnt/boot/efi
mount $EFI /mnt/boot/efi
swapon $SWAP

echo "==> Installing base system..."

pacstrap /mnt base linux linux-firmware sof-firmware grub efibootmgr networkmanager base-devel nano
echo "==> Generating fstab..."

genfstab -U /mnt >> /mnt/etc/fstab

echo "==> Setting up chroot..."

arch-chroot /mnt /bin/bash << EOF
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo $HOST > /etc/hostname
echo root:$ROOTPASS | chpasswd

# Create user archV and add to wheel group for sudo
useradd -m -G wheel -s /bin/bash $USER
echo $USER:$USERPASS | chpasswd

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

grub-install $DISK
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
EOF

echo "==> Unmounting and done!"

umount -a

echo "Arch installation complete. Reboot when ready!"
