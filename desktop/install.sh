#! /usr/bin/env bash

set -euo pipefail

# shellcheck source=common/common.sh
. "../common/common.sh"

NETWORK_NAME="$1"
HOST_NAME="$2"
TIME_ZONE="${3:Australia/Melbourne}"

info "Setup Archlinux from ISO on desktop"

WIRELESS_DEVICE="$(iwctl device list)"

info "Connect to WIFI $NETWORK_NAME"

iwctl station "$WIRELESS_DEVICE" connect "$NETWORK_NAME"

iwctl station "$WIRELESS_DEVICE" show

if ! ping -oc 5 archlinux.org > /dev/null; then
	error "Not connected to Internet"
fi

info "Enable NTP"
timedatectl set-ntp true

TARGET_DEVICE=/dev/nvme0n1
OS_PARTITION_LABEL=ARCH
OS_PARTITION_PATH="/dev/disk/by-partlabel/$OS_PARTITION_LABEL"
EFI_PARTITION_LABEL="EFISYSTEM"
EFI_PARTITION_PATH="/dev/disk/by-partlabel/$EFI_PARTITION_LABEL"
SWAP_PARTITION_LABEL="SWAP"
SWAP_PARTITION_PATH="/dev/disk/by-partlabel/$SWAP_PARTITION_LABEL"

info "Zero out disk $TARGET_DEVICE"
sgdisk -Z "$TARGET_DEVICE"
info "Create disk partitions on $TARGET_DEVICE"
gdisk \
	-n1:0:+512M -t1:ef00 -c1:"$EFI_PARTITION_LABEL" \
	-n2:0:+16G -t2:8200 -c2:"$SWAP_PARTITION_LABEL" \
	-N3 -t3:8304 -c3:"$OS_PARTITION_LABEL" \
	"$TARGET_DEVICE"
sleep 5
partprobe -s "$TARGET_DEVICE"

while [ ! -b "$OS_PARTITION_PATH" ]; do
	echo "Wait for device to be ready"
	sleep 5
done

info "Setup LUKS encryption on $OS_PARTITION_PATH"
cryptsetup luksFormat --type luks2 "$OS_PARTITION_PATH"
cryptsetup luksOpen "$OS_PARTITION_PATH" root

info "Setup LUKS encryption on $SWAP_PARTITION_PATH"
cryptsetup luksFormat --type luks2 "$SWAP_PARTITION_PATH"
cryptsetup luksOpen "$SWAP_PARTITION_PATH" swap

info "Create and mount file system mount points"
ROOT_DEVICE=/dev/mapper/root
SWAP_DEVICE=/dev/mapper/swap
mkfs.fat -F32 -n boot "$EFI_PARTITION_PATH"
mkfs.btrfs -f -L arch "$ROOT_DEVICE"
mkswap "$SWAP_DEVICE"

mount "$ROOT_DEVICE" /mnt
mkdir /mnt/efi
mount "$EFI_PARTITION_PATH" /mnt/efi
for subvol in var var/log var/cache var/tmp srv home; do
	btrfs subvolume create "/mnt/$subvol"
done

info "Tune swap performance"
echo "vm.swappiness=10" > /mnt/etc/sysctl.d/99-swappiness.conf

info "Setup timezone"
ln -sf "/usr/share/zoneinfo/${TIME_ZONE}" /mnt/etc/localtime

info "Setup hostname"
echo "$HOST_NAME" >/mnt/etc/hostname

info "Install base packages"
reflector --verbose --latest 5 --sort rate --protocol https --country Australia --save /etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel neovim git openssh amd-ucode \
yubikey-manager reflector linux-zen linux-zen-headers linux-firmware dracut btrfs-progs \
xf86-video-amdgpu mesa vulkan-radeon libva-mesa-driver

info "Setup locale"
sed -i -e '/^#en_AU.UTF-8/s/^#//' /mnt/etc/locale.gen
sed -i -e '/^#zh_CN.UTF-8/s/^#//' /mnt/etc/locale.gen

cat<<EOF > /mnt/etc/locale.conf
LANG=en_AU.UTF-8
LANGUAGE=en_AU:zh_CN
EOF
echo 'KEYMAP=us' > /mnt/etc/vconsole.conf

info "Setup dracut"
DRACUT_CONF_DIR="/mnt/etc/dracut.conf.d"
if [ ! -d "$DRACUT_CONF_DIR" ]; then
	mkdir -p "$DRACUT_CONF_DIR"
fi

cat <<EOF > "$DRACUT_CONF_DIR/arch-defaults.conf"
hostonly=yes
hostonly_cmdline=no
compress=lz4
show_modules=yes

add_drivers+=" lz4 lz4_compress "
omit_dracutmodules+=" iscsi mdraid  "
uefi=yes
early_microcode=yes
CMDLINE=(
	zswap.enabled=1
	zswap.compressor=lz4
	zswap.zpool=z3fold
)
kernel_cmdline+=" ${CMDLINE[*]} "
unset CMDLINE
EOF

cat <<EOF > "$DRACUT_CONF_DIR/gpu-kms.conf"
add_drivers+=" amdgpu "
EOF

info "Post install"
arch-chroot /mnt
locale-gen
hwclock --systohc --utc
systemctl enable systemd-homed
systemctl enable systemd-timesyncd
passwd root
pacman -S --noconfirm --asdeps binutils elfutils
dracut -f --regenerate-all
bootctl install
swapon /swap/swapfile
reboot
