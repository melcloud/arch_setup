#! /usr/bin/env bash

tune_swap() {
	info_log "Tune swap performance"
	echo "vm.swappiness=10" > /mnt/etc/sysctl.d/99-swappiness.conf
}
