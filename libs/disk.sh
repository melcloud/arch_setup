#! /usr/bin/env bash

function format_disk() {
	local TARGET_DEVICE="$1"
	read -r -s -p "LUKS password: " password

	OS_PARTITION_LABEL=ARCH
	OS_PARTITION_PATH="/dev/disk/by-partlabel/$OS_PARTITION_LABEL"
	EFI_PARTITION_LABEL="EFISYSTEM"
	EFI_PARTITION_PATH="/dev/disk/by-partlabel/$EFI_PARTITION_LABEL"
	SWAP_PARTITION_LABEL="SWAP"
	SWAP_PARTITION_PATH="/dev/disk/by-partlabel/$SWAP_PARTITION_LABEL"

	info_log "Zero out disk $TARGET_DEVICE"
	dd if=/dev/zero of="$TARGET_DEVICE" bs=1M status=progress
	sgdisk -Z "$TARGET_DEVICE"
	info_log "Create disk partitions on $TARGET_DEVICE"
	sgdisk \
		-n1:0:+512M -t1:ef00 -c1:"$EFI_PARTITION_LABEL" \
		-n2:0:+16G -t2:8200 -c2:"$SWAP_PARTITION_LABEL" \
		-N3 -t3:8304 -c3:"$OS_PARTITION_LABEL" \
		"$TARGET_DEVICE"
	sleep 5
	partprobe -s "$TARGET_DEVICE"

	while [ ! -b "$OS_PARTITION_PATH" ]; do
		info_log "Wait for device to be ready"
		sleep 5
	done

	info_log "Setup LUKS encryption on $OS_PARTITION_PATH"
	echo -n "$password" | cryptsetup luksFormat --type luks2 "$OS_PARTITION_PATH" -d -
	echo -n "$password" | cryptsetup luksOpen "$OS_PARTITION_PATH" root -d -

	info_log "Setup LUKS encryption on $SWAP_PARTITION_PATH"
	echo -n "$password" | cryptsetup luksFormat --type luks2 "$SWAP_PARTITION_PATH" -d -
	echo -n "$password" | cryptsetup luksOpen "$SWAP_PARTITION_PATH" swap -d -

	info_log "Create and mount file system mount points"
	ROOT_DEVICE=/dev/mapper/root
	SWAP_DEVICE=/dev/mapper/swap
	mkfs.fat -F32 -n BOOT "$EFI_PARTITION_PATH"
	mkfs.btrfs -f -L ARCH "$ROOT_DEVICE"
	mkswap "$SWAP_DEVICE"

	mount "$ROOT_DEVICE" /mnt
	mkdir /mnt/efi
	mount "$EFI_PARTITION_PATH" /mnt/efi
	for subvol in var var/log var/cache var/tmp srv home; do
		btrfs subvolume create "/mnt/$subvol"
	done
}
