#!/usr/bin/env bash

function setup_dracut() {
	local additional_drivers="$1"

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
		quiet
	)
	kernel_cmdline=" \${CMDLINE[*]} "
	unset CMDLINE
EOF

	cat <<EOF > "$DRACUT_CONF_DIR/kms.conf"
	add_drivers+=" ${additional_drivers} "
EOF
}
