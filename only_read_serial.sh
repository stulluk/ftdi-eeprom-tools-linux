#!/usr/bin/env bash
set -euo pipefail

TTY_DEVICE="${1:-/dev/ttyUSB0}"

if [[ "${TTY_DEVICE}" == "-h" || "${TTY_DEVICE}" == "--help" ]]; then
  echo "Usage: $0 [tty_device]"
  echo "Example: $0 /dev/ttyUSB0"
  exit 0
fi

if [[ ! -e "${TTY_DEVICE}" ]]; then
  echo "Error: ${TTY_DEVICE} not found."
  exit 1
fi

echo "Reading serial info from ${TTY_DEVICE}"
udevadm info --query=property --name="${TTY_DEVICE}" | rg '^ID_SERIAL(_SHORT)?='
