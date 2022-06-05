#! /usr/bin/env bash

set -euo pipefail

function info() {
	echo "[INFO] $1"
}

function error() {
	echo "[ERROR] $1"
	exit 1
}
