#!/usr/bin/env bash
set -euo pipefail

# Pin to the Linux row published on FTDI's D2XX drivers page (update when FTDI bumps).
# Index: https://ftdichip.com/drivers/d2xx-drivers/
readonly FTDI_D2XX_LINUX_VERSION="1.4.34"
readonly FTDI_D2XX_RELEASE_PATH="2025/11"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READ_DIR="${SCRIPT_DIR}/linux-x86_64/examples/EEPROM/read"
WRITE_SRC="${SCRIPT_DIR}/linux-x86_64/ft_eeprom_write_serial.c"
WRITE_BIN="${SCRIPT_DIR}/linux-x86_64/ft_eeprom_write_serial"
TTY_DEVICE="${TTY_DEVICE:-/dev/ttyUSB0}"
MAX_SERIAL_LEN=16
UNLOADED_USB_SERIAL=0
UNLOADED_FTDI_SIO=0
UNLOADED_USB_SERIAL_CLIENTS=()

usage() {
  echo "Usage: sudo $0 <new_serial>"
  echo "Reads current serial from ${TTY_DEVICE}, then writes <new_serial> to EEPROM."
  echo "Max serial length: ${MAX_SERIAL_LEN} chars"
  echo ""
  echo "Environment:"
  echo "  FTDI_D2XX_NO_AUTO_DOWNLOAD=1  Do not download/install libftd2xx from FTDI on link failure."
  echo "  FTDI_D2XX_URL=<url>           Override tarball URL (must match this machine's CPU ABI)."
}

deb_host_multiarch() {
  if command -v dpkg-architecture >/dev/null 2>&1; then
    dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || true
  fi
}

d2xx_lib_search_flags() {
  local -a flags=(-L/usr/local/lib)
  local m
  m=$(deb_host_multiarch)
  if [[ -n "${m}" && -d "/usr/lib/${m}" ]]; then
    flags+=(-L"/usr/lib/${m}")
  fi
  printf '%s\n' "${flags[@]}"
}

d2xx_rpath_flags() {
  local line d
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    d="${line#-L}"
    printf '%s\n' "-Wl,-rpath,${d}"
  done < <(d2xx_lib_search_flags)
}

d2xx_install_dir() {
  local m
  m=$(deb_host_multiarch)
  if [[ -n "${m}" && -d "/usr/lib/${m}" ]]; then
    echo "/usr/lib/${m}"
  else
    echo "/usr/local/lib"
  fi
}

# Return 0 if this shared object matches the running userspace ABI (rough check via file(1)).
d2xx_so_matches_host() {
  local so="$1"
  local desc
  desc=$(file -b "${so}" 2>/dev/null || true)
  case "$(uname -m)" in
    x86_64)
      [[ "${desc}" == *"x86-64"* ]]
      ;;
    i386 | i486 | i586 | i686)
      [[ "${desc}" == *"Intel i386"* ]] || [[ "${desc}" == *"80386"* ]]
      ;;
    aarch64)
      [[ "${desc}" == *"aarch64"* ]]
      ;;
    armv7l | armv6l)
      [[ "${desc}" == *"ARM"* ]]
      ;;
    *)
      return 1
      ;;
  esac
}

find_usable_system_d2xx_so() {
  local -a candidates=()
  local m c
  candidates+=("/usr/local/lib/libftd2xx.so")
  m=$(deb_host_multiarch)
  if [[ -n "${m}" ]]; then
    candidates+=("/usr/lib/${m}/libftd2xx.so")
  fi
  for c in "${candidates[@]}"; do
    if [[ -f "${c}" ]] && d2xx_so_matches_host "${c}"; then
      echo "${c}"
      return 0
    fi
  done
  return 1
}

# Default tarball for this host, from FTDI's Linux D2XX table (same version for all rows).
d2xx_default_tarball_url() {
  if [[ -n "${FTDI_D2XX_URL:-}" ]]; then
    echo "${FTDI_D2XX_URL}"
    return 0
  fi
  local v="${FTDI_D2XX_LINUX_VERSION}"
  local p="${FTDI_D2XX_RELEASE_PATH}"
  local base="https://ftdichip.com/wp-content/uploads/${p}"
  case "$(uname -m)" in
    x86_64)
      echo "${base}/libftd2xx-linux-x86_64-${v}.tgz"
      ;;
    i386 | i486 | i586 | i686)
      echo "${base}/libftd2xx-linux-x86_32-${v}.tgz"
      ;;
    aarch64)
      echo "${base}/libftd2xx-linux-arm-v8-${v}.tgz"
      ;;
    armv7l)
      # Common on Raspberry Pi OS; if this is wrong for your board, set FTDI_D2XX_URL to the
      # ARMv7 soft-float / uClibc / ARMv6 package from FTDI's table.
      echo "${base}/libftd2xx-linux-arm-v7-hf-${v}.tgz"
      ;;
    armv6l)
      echo "${base}/libftd2xx-linux-arm-v6-hf-${v}.tgz"
      ;;
    *)
      echo ""
      return 1
      ;;
  esac
}

fetch_and_install_d2xx_from_ftdi() {
  local url dest_dir tmp tgz so found
  url=$(d2xx_default_tarball_url) || true
  if [[ -z "${url}" ]]; then
    echo "Error: unsupported machine $(uname -m) for automatic D2XX download."
    echo "Install libftd2xx.so manually from https://ftdichip.com/drivers/d2xx-drivers/"
    echo "or set FTDI_D2XX_URL to the correct .tgz for this CPU."
    return 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required for automatic download. Install curl or install libftd2xx manually."
    return 1
  fi

  dest_dir=$(d2xx_install_dir)
  tmp=$(mktemp -d)
  tgz="${tmp}/libftd2xx.tgz"
  echo "[libftd2xx] Downloading D2XX tarball from FTDI:"
  echo "  ${url}"
  echo "[libftd2xx] Installing shared library under: ${dest_dir}"
  curl -fsSL --retry 3 --connect-timeout 15 -o "${tgz}" "${url}"
  tar xzf "${tgz}" -C "${tmp}"
  found=""
  while IFS= read -r -d '' so; do
    if d2xx_so_matches_host "${so}"; then
      found="${so}"
      break
    fi
  done < <(find "${tmp}" -name libftd2xx.so -type f -print0 2>/dev/null)

  if [[ -z "${found}" ]]; then
    echo "Error: could not locate a host-matching libftd2xx.so inside the tarball."
    return 1
  fi

  install -m 0755 "${found}" "${dest_dir}/libftd2xx.so"
  ldconfig
  rm -rf "${tmp}"
  echo "[libftd2xx] Installed. Re-trying build."
}

ensure_libftd2xx_installed_from_ftdi_if_missing() {
  if find_usable_system_d2xx_so >/dev/null; then
    return 0
  fi

  if [[ -n "${FTDI_D2XX_NO_AUTO_DOWNLOAD:-}" ]]; then
    echo "Error: libftd2xx.so not found (and FTDI_D2XX_NO_AUTO_DOWNLOAD is set)."
    echo "Install from https://ftdichip.com/drivers/d2xx-drivers/ then re-run."
    return 1
  fi

  echo "[libftd2xx] No usable system libftd2xx.so found; downloading from FTDI (set FTDI_D2XX_NO_AUTO_DOWNLOAD=1 to disable)."
  fetch_and_install_d2xx_from_ftdi
}

build_write_tool() {
  local -a gcc_cmd=(gcc -o "${WRITE_BIN}" "${WRITE_SRC}" -lftd2xx)
  local line
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    gcc_cmd+=("${line}")
  done < <(d2xx_lib_search_flags)
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    gcc_cmd+=("${line}")
  done < <(d2xx_rpath_flags)
  "${gcc_cmd[@]}"
}

try_make_read() {
  if make -C "${READ_DIR}"; then
    return 0
  fi
  echo "Warning: EEPROM read tool build failed (often missing libftd2xx)."
  if [[ -n "${FTDI_D2XX_NO_AUTO_DOWNLOAD:-}" ]]; then
    echo "FTDI_D2XX_NO_AUTO_DOWNLOAD is set; not downloading. Re-running make:"
    make -C "${READ_DIR}"
    return
  fi
  ensure_libftd2xx_installed_from_ftdi_if_missing
  make -C "${READ_DIR}"
}

try_build_write_with_optional_fetch() {
  if build_write_tool; then
    return 0
  fi

  echo "Warning: EEPROM write tool build failed (often missing libftd2xx)."
  if [[ -n "${FTDI_D2XX_NO_AUTO_DOWNLOAD:-}" ]]; then
    echo "FTDI_D2XX_NO_AUTO_DOWNLOAD is set; not downloading. Re-running compiler:"
    build_write_tool
    return
  fi

  ensure_libftd2xx_installed_from_ftdi_if_missing
  build_write_tool
}

is_module_loaded() {
  local module_name="$1"
  lsmod | grep -i "^${module_name}[[:space:]]"
}

unload_usbserial_client_modules() {
  # These drivers commonly depend on usbserial and can block rmmod usbserial.
  local -a candidates=(pl2303 cp210x ch341 f81534 ftdi_sio)
  local mod
  for mod in "${candidates[@]}"; do
    if [[ "${mod}" == "ftdi_sio" ]]; then
      # ftdi_sio is handled separately for clearer logs and state tracking.
      continue
    fi
    if is_module_loaded "${mod}" >/dev/null; then
      if rmmod "${mod}"; then
        UNLOADED_USB_SERIAL_CLIENTS+=("${mod}")
        echo "Unloaded usbserial client: ${mod}"
      else
        echo "Warning: failed to unload usbserial client: ${mod}"
      fi
    fi
  done
}

reload_usbserial_client_modules() {
  local mod
  if (( ${#UNLOADED_USB_SERIAL_CLIENTS[@]} == 0 )); then
    return 0
  fi
  for mod in "${UNLOADED_USB_SERIAL_CLIENTS[@]}"; do
    if modprobe "${mod}"; then
      echo "Loaded usbserial client: ${mod}"
    else
      echo "Warning: failed to load usbserial client: ${mod}"
    fi
  done
}

unload_serial_modules() {
  echo "[4/7] Unloading kernel drivers (rmmod)"
  if is_module_loaded "ftdi_sio"; then
    rmmod ftdi_sio
    UNLOADED_FTDI_SIO=1
    echo "Unloaded: ftdi_sio"
  else
    echo "Skip: ftdi_sio not loaded"
  fi

  unload_usbserial_client_modules

  if is_module_loaded "usbserial"; then
    rmmod usbserial
    UNLOADED_USB_SERIAL=1
    echo "Unloaded: usbserial"
  else
    echo "Skip: usbserial not loaded"
  fi
}

reload_serial_modules() {
  echo "[7/7] Reloading kernel drivers (modprobe)"
  if (( UNLOADED_USB_SERIAL == 1 )); then
    if modprobe usbserial; then
      echo "Loaded: usbserial"
    else
      echo "Warning: failed to load usbserial with modprobe"
    fi
  else
    echo "Skip: usbserial was not unloaded by this script"
  fi

  reload_usbserial_client_modules

  if (( UNLOADED_FTDI_SIO == 1 )); then
    if modprobe ftdi_sio; then
      echo "Loaded: ftdi_sio"
    else
      echo "Warning: failed to load ftdi_sio with modprobe"
    fi
  else
    echo "Skip: ftdi_sio was not unloaded by this script"
  fi
}

restore_drivers_on_exit() {
  # Always attempt to restore to prevent leaving system in detached state.
  reload_serial_modules || true
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if (( EUID != 0 )); then
  echo "Error: run with sudo/root."
  exit 1
fi

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

NEW_SERIAL="$1"
if (( ${#NEW_SERIAL} > MAX_SERIAL_LEN )); then
  echo "Error: serial too long (${#NEW_SERIAL}). Max is ${MAX_SERIAL_LEN}."
  exit 1
fi

if [[ ! -e "${TTY_DEVICE}" ]]; then
  echo "Error: ${TTY_DEVICE} not found."
  exit 1
fi

trap restore_drivers_on_exit EXIT

echo "[1/7] Current tty serial via udevadm (${TTY_DEVICE})"
udevadm info --query=property --name="${TTY_DEVICE}" | rg '^ID_SERIAL(_SHORT)?=' || true

echo "[2/7] Building EEPROM read tool"
try_make_read

echo "[3/7] Building EEPROM write tool"
try_build_write_with_optional_fetch

unload_serial_modules

echo "[5/7] Writing new serial: ${NEW_SERIAL}"
"${WRITE_BIN}" "${NEW_SERIAL}"

printf "reloading serial kernel modules...\n"
reload_serial_modules

COUNTDOWN=3

printf "Sleeping for %d seconds...\n" "${COUNTDOWN}"
for ((i = COUNTDOWN; i >= 1; i--)); do
  echo "$i"
  sleep 1
done

echo "[6/7] Read serial after write (udev may need replug/rebind to refresh)"
udevadm info --query=property --name="${TTY_DEVICE}" | grep "ID_SERIAL_SHORT" || true

echo "Done. Please unplug / replug and run only_read_serial.sh"
