#! /usr/bin/env bash

set -euo pipefail

help()
{
	echo "Usage: install
		[ -n | --network-name ]
		[ -H | --host-name ]
		[ -t | --time-zone ]
		[ -F | --format-disk <true|false> ]
		[ -h | --help  ]"
	exit 2
}

. "../libs/logging.sh"
. "../libs/network.sh"
. "../libs/disk.sh"
. "../libs/locale.sh"
. "../libs/perf.sh"
. "../libs/pacstrap.sh"
. "../libs/dracut.sh"
. "../libs/chroot.sh"

SHORT=n:,H:,t:,F:,h
LONG=network-name:,host-name:,time-zone:,format-disk:,help
OPTS=$(getopt -a -n install --options $SHORT --longoptions $LONG -- "$@")

VALID_ARGUMENTS=$# # Returns the count of arguments that are in short or long options

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help
fi

eval set -- "$OPTS"

HOST_NAME=''
TIME_ZONE=''
NETWORK_NAME=''
FORMAT_DISK=false

while :
do
	case "$1" in
	-n | --network-name )
		NETWORK_NAME="$2"
		shift 2
		;;
	-H | --host-name )
		HOST_NAME="$2"
		shift 2
		;;
	-t | --time-zone )
		TIME_ZONE="2"
		shift 2
		;;
	-F | --format-disk )
		FORMAT_DISK="$2"
		shift 2
		;;
	-h | --help)
		help
		;;
	--)
		shift;
		break
		;;
	*)
		echo "Unexpected option: $1"
		help
		;;
  esac
done

if [ -z "$HOST_NAME" ]; then
	error_exit_log "Host name is required by using -H or --host-name argument"
fi

if [ -z "$TIME_ZONE" ]; then
	TIME_ZONE="Australia/Melbourne"
fi

info_log "Setup Archlinux from ISO on desktop"

connect_to_internet "$NETWORK_NAME"

if [ "$FORMAT_DISK" = true ]; then
	format_disk "/dev/nvme0n1"
fi

pacstrap_install

setup_time "$TIME_ZONE"
setup_host_name "$HOST_NAME"
tune_swap

info_log "Setup dracut"
setup_dracut "amdgpu"

info_log "Chroot and perform post installation"
chroot_install
info_log "Installation completed"
