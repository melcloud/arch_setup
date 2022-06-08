#! /usr/bin/env bash

chroot_install() {
	read -sr -p "Root password: " root_password
	arch-chroot /mnt <<EOF
	locale-gen
	hwclock --systohc --utc
	systemctl enable systemd-homed
	systemctl enable systemd-timesyncd
	systemctl enable systemd-boot-update
	echo "root:$root_password" | chpasswd
	pacman -S --noconfirm --needed --asdeps binutils elfutils
	dracut -f --regenerate-all
	bootctl install
EOF
}
