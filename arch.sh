#!/bin/bash

set -e

DISK="/dev/nvme"  # Replace with your actual disk, e.g. /dev/sda or /dev/nvme0n1
HOST=""   #hostname
HOSTPASS=""	#host password
ROOTPASS=""	#root password

EFI="${DISK}p"
SWAP="${DISK}p"
ROOT="${DISK}p"

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
useradd -m -G wheel -s /bin/bash $HOST
echo $HOST:$HOSTPASS | chpasswd

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

grub-install $DISK
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager

EOF

echo "==> Unmounting and done!"

umount -a

echo "Arch installation complete. Reboot when ready!"
