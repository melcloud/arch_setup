#! /usr/bin/env bash

function setup_locale() {
	info_log "Setup locale"
	sed -i -e '/^#en_AU.UTF-8/s/^#//' /mnt/etc/locale.gen
	sed -i -e '/^#en_GB.UTF-8/s/^#//' /mnt/etc/locale.gen
	sed -i -e '/^#zh_CN.UTF-8/s/^#//' /mnt/etc/locale.gen

	cat<<EOF > /mnt/etc/locale.conf
	LANG=en_AU.UTF-8
	LANGUAGE=en_AU:en_GB:en
EOF
	echo 'KEYMAP=us' > /mnt/etc/vconsole.conf
}
