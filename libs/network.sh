#! /usr/bin/env bash

function connect_to_internet() {
	local network_name="$1"

	if ! ping -qc 1 archlinux.org > /dev/null 2>&1; then
		if [ -z "$network_name" ]; then
			error_exit_log "Network name is required by using -n or --network-name argument"
		fi

		local WIRELESS_DEVICE
		WIRELESS_DEVICE="$(printf '%s\n' /sys/class/net/*/wireless | cut -d/ -f5)"

		info_log "Connect to WIFI $network_name"

		iwctl station "$WIRELESS_DEVICE" connect "$network_name"

		iwctl station "$WIRELESS_DEVICE" show
	fi

	# Check again to make sure there is network connectivity

	if ping -qc 1 archlinux.org > /dev/null 2>&1; then
		info_log "Connected to internet"
	else
		error_exit_log "No Internet connection, re-try the iwctl commands"
	fi
}

function setup_time() {
	local tz="$1"

	info_log "Enable NTP"
	timedatectl set-ntp true

	info_log "Setup timezone"
	ln -sf "/usr/share/zoneinfo/${tz}" /mnt/etc/localtime
}

function setup_host_name() {
	local host_name="$1"

	info_log "Set hostname to $host_name"
	echo "$host_name" >/mnt/etc/hostname
}
