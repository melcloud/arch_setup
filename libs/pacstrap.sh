#! /usr/bin/env bash

function pacstrap_install() {
	local cpu_vendor
	local base_packages
	cpu_vendor="$(lscpu | awk '/^Vendor ID/{ print $3 }')"
	base_packages=(
		'base' 'base-devel'
		'linux-zen' 'linux-zen-headers' 'linux-firmware' 'dracut' 'btrfs-progs'
		'libfido2' 'reflector' 'neovim' 'git' 'openssh' 'mesa'
		'tpm2-tools' 'sbctl' 'rng-tools'
	)

	if [[ "$cpu_vendor" == "GenuineIntel" ]]; then
		base_packages+=('intel-ucode' 'intel-media-driver' 'vulkan-intel')
	elif [[ "$cpu_vendor" == "AuthenticAMD" ]]; then
		base_packages+=('amd-ucode' 'xf86-video-amdgpu' 'vulkan-radeon' 'libva-mesa-driver')
	else
		error_exit_log "The CPU is not Intel or AMD, not sure what to use"
	fi

	info_log "Install base packages"
	reflector --verbose -l 3 --sort rate --protocol https --country Australia --save /etc/pacman.d/mirrorlist

	pacstrap /mnt "${base_packages[@]}"
}
