#! /usr/bin/env bash

function setup_locale() {
	info_log "Setup locale"
	sed -i -e '/^#en_AU.UTF-8/s/^#//' /mnt/etc/locale.gen
	sed -i -e '/^#zh_CN.UTF-8/s/^#//' /mnt/etc/locale.gen

	cat<<EOF > /mnt/etc/locale.conf
	LANG=en_AU.UTF-8
	LANGUAGE=en_AU:zh_CN
EOF
	echo 'KEYMAP=us' > /mnt/etc/vconsole.conf
}
