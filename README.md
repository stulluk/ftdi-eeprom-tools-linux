# ftdi-eeprom-tools-linux

FTDI EEPROM Serial Number Programming Tools for Linux

This repository contains tools for changing serial numbers in the internal EEPROM of FTDI chips. It is based on FTDI's official libftd2xx library and example code.

## ⚠️ Warning

There are many USB-serial cables on the market that claim to use original FT232R/RL chips, but most of them are **fake/counterfeit**. These fake chips do not have writable internal EEPROMs, so the EEPROM writing examples in this repository will **not work** with them.

This repository has been tested with at least 10 different cables from the market, and the only cable that successfully worked was **WaveShare's USB to Serial cable**. If you are planning to use these tools, make sure you have a genuine FTDI chip with a writable EEPROM.

## License

This code includes FTDI's libftd2xx library and examples. License information has been preserved without modification. See the license header in `linux-x86_64/ftd2xx.h` for details.

**Important:** FTDI DRIVERS MAY BE DISTRIBUTED IN ANY FORM AS LONG AS LICENSE INFORMATION IS NOT MODIFIED.

## Purpose & Advantages

1. **Port Independence:** Devices get the same device node regardless of which USB port they're plugged into
2. **Easy Identification:** You can use meaningful names for each device
3. **Script Compatibility:** You can use fixed names like `/dev/serial-apple` in your scripts
4. **Multiple Device Support:** Even if you have multiple FTDI devices, each will have its own unique node

## Modifications

Main modifications made to the original FTDI code in this repository:

### 1. EEPROM Write Example Enhancements (`examples/EEPROM/write/main.c`)

The original code determined device type at compile-time using `#ifdef`. The changes made:

- **Automatic Device Detection:** Device type is automatically detected at runtime using the `FT_GetDeviceInfo()` function
- **Multiple Device Support:** Separate configurations for FT_DEVICE_BM, FT_DEVICE_232R, and FT_DEVICE_2232C device types
- **FT232R Improvements:** Special configuration for FT232R devices (CBUS pin settings, SerNumEnableR, etc.)
- **Serial Number:** Default serial number set to "SERTAC-WS1" (can be changed in code)

### 2. Command Line Serial Number Tool (`ft_eeprom_write_serial.c`)

A newly added utility program:

- Reads current EEPROM contents
- Takes new serial number from command line
- Updates EEPROM
- Usage: `sudo ./ft_eeprom_write_serial <new_serial_number>`

## Requirements

- Linux on **x86_64** (amd64). The scripts and examples here are used on 64-bit PCs.
- GCC
- **FTDI D2XX** user-space library **`libftd2xx.so`** installed on the system (see below). This is **not** the same as Debian/Ubuntu `libftdi-dev` (open-source libFTDI).
- Root privileges (for EEPROM writing)

The Git repository ships **FTDI headers and modified example/tool source**. FTDI’s **prebuilt `libftd2xx.so` binary** is normally **not** committed here; you install it from FTDI’s official Linux D2XX package.

## Installation and Build

### 1. Where `libftd2xx.so` comes from (official FTDI D2XX for Linux)

All **Linux** `.tgz` builds of **libftd2xx** (x86 32-bit, x86 64-bit, ARM variants, MIPS, …) are published on FTDI’s **D2XX Drivers** page — open the **Linux** row in the table and pick the column that matches your CPU ABI:

- **[D2XX Drivers (FTDI)](https://ftdichip.com/drivers/d2xx-drivers/)**

That page is the canonical source; direct `wp-content/uploads/...` URLs move when FTDI bumps a version. When in doubt, download from the table rather than bookmarking a single `.tgz` forever.

**Not** `libftdi-dev`: Debian/Ubuntu `libftdi-dev` installs the open-source **libFTDI** stack (`ftdi.h`, `-lftdi`). This project links **FTDI’s proprietary D2XX** API (`ftd2xx.h`, `-lftd2xx`). They are different libraries.

#### Linux 1.4.34 (2025-11-11 row) — direct download examples

These links mirror the current **Linux / 1.4.34** cells on the D2XX page (use the page if a link 404s):

| Variant | Typical use | Direct `.tgz` link |
|--------|----------------|--------------------|
| x86 (32-bit) | 32-bit Linux userspace (`uname -m` i686, …) | [libftd2xx-linux-x86_32-1.4.34.tgz](https://ftdichip.com/wp-content/uploads/2025/11/libftd2xx-linux-x86_32-1.4.34.tgz) |
| x64 (64-bit) | PCs and servers (`uname -m` x86_64) | [libftd2xx-linux-x86_64-1.4.34.tgz](https://ftdichip.com/wp-content/uploads/2025/11/libftd2xx-linux-x86_64-1.4.34.tgz) |
| ARMv7 soft-float | Boards using soft-float ABI | [libftd2xx-linux-arm-v7-sf-1.4.34.tgz](https://ftdichip.com/wp-content/uploads/2025/11/libftd2xx-linux-arm-v7-sf-1.4.34.tgz) |
| ARMv7 hard-float | Many **Raspberry Pi** systems (check your image) | [libftd2xx-linux-arm-v7-hf-1.4.34.tgz](https://ftdichip.com/wp-content/uploads/2025/11/libftd2xx-linux-arm-v7-hf-1.4.34.tgz) |
| ARMv7 hard-float uClibc | uClibc-based ARM toolchains | [libftd2xx-linux-arm-v7-hf-uclibc-1.4.34.tgz](https://ftdichip.com/wp-content/uploads/2025/11/libftd2xx-linux-arm-v7-hf-uclibc-1.4.34.tgz) |
| ARMv6 hard-float | Older Raspberry Pi models (FTDI footnote: check instruction set) | [libftd2xx-linux-arm-v6-hf-1.4.34.tgz](https://ftdichip.com/wp-content/uploads/2025/11/libftd2xx-linux-arm-v6-hf-1.4.34.tgz) |
| ARMv8 | AArch64 SBCs (`uname -m` aarch64) | [libftd2xx-linux-arm-v8-1.4.34.tgz](https://ftdichip.com/wp-content/uploads/2025/11/libftd2xx-linux-arm-v8-1.4.34.tgz) |

FTDI’s page notes that if you are unsure which **ARM** tarball matches your board, compare `file` / `readelf` on a known-good system binary with `release/build/libftd2xx.txt` inside each tarball, and see their [Linux ReadMe](https://ftdichip.com/Driver/D2XX/Linux/ReadMe.txt), release notes, and install video linked from the same table.

**Important:** A **32-bit** `libftd2xx.so` cannot be linked by a normal **64-bit** `gcc` build (and vice versa). After copying a library, run `file libftd2xx.so` and confirm the ELF class matches your host (for example **ELF 64-bit … x86-64** on `x86_64`).

Extract the archive; the shared object lives under a top-level directory such as `linux-x86_64/`, `linux-x86_32/`, or the ARM-prefixed folder inside the tarball.

### 2. Install `libftd2xx.so` on your system

On Debian-derived systems with multiarch, libraries often live under `/usr/lib/<triplet>/` (for example `/usr/lib/x86_64-linux-gnu/`). `/usr/local/lib` is also fine. The `read_then_write_serial.sh` helper passes **both** `-L/usr/local/lib` and `-L/usr/lib/<triplet>` (when `dpkg-architecture` reports a triplet) so the linker can find the D2XX library in either location.

Manual install example (adjust paths to match what you extracted):

```bash
# Example: x86_64 tarball extracted so that ./linux-x86_64/libftd2xx.so exists
sudo install -m 0755 linux-x86_64/libftd2xx.so /usr/local/lib/libftd2xx.so
sudo ldconfig
```

Or install into the multiarch directory (get triplet with `dpkg-architecture -qDEB_HOST_MULTIARCH`):

```bash
triplet=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
sudo install -m 0755 linux-x86_64/libftd2xx.so "/usr/lib/${triplet}/libftd2xx.so"
sudo ldconfig
```

If your tarball only ships a versioned filename (for example `libftd2xx.so.1.4.33`), copy that file under `/usr/local/lib/` or `/usr/lib/<triplet>/` and add a `libftd2xx.so` symlink pointing to it, then run `sudo ldconfig`.

### Optional: automatic libftd2xx download

If the EEPROM **read** or **write** build fails (commonly `cannot find -lftd2xx`), `read_then_write_serial.sh` can **download the matching official `.tgz` from FTDI**, extract it to a temporary directory, install `libftd2xx.so`, run `ldconfig`, and retry the build. This uses `curl` and requires network access.

- **Disable** this behaviour: `sudo FTDI_D2XX_NO_AUTO_DOWNLOAD=1 ./read_then_write_serial.sh NEWSERIAL`
- **Override** the tarball URL (for example a different ARM ABI): `sudo FTDI_D2XX_URL='https://…/libftd2xx-linux-arm-v7-sf-1.4.34.tgz' ./read_then_write_serial.sh NEWSERIAL`

The script pins a default version (`1.4.34`) and upload path (`2025/11`) to match the current Linux row; when FTDI publishes a newer row, update the constants at the top of `read_then_write_serial.sh` or use `FTDI_D2XX_URL`.

**Trust / ops note:** automatic download installs a **binary** from the network onto your system (as root). That is convenient for lab machines but is a supply-chain decision: use manual installs or `FTDI_D2XX_NO_AUTO_DOWNLOAD=1` when you need stricter control.

### 3. EEPROM Write Example Build

```bash
cd linux-x86_64/examples/EEPROM/write
make
```

This command creates an executable named `write`.

### 4. Command Line Serial Number Tool Build

From the **`linux-x86_64/` directory at the root of this repository** (the modified sources and `ft_eeprom_write_serial.c`):

```bash
cd linux-x86_64
gcc -o ft_eeprom_write_serial ft_eeprom_write_serial.c -lftd2xx -L/usr/local/lib -Wl,-rpath /usr/local/lib
```

Add `-L/usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)` and a matching `-Wl,-rpath,...` when you install the `.so` under the multiarch directory. The root `read_then_write_serial.sh` already includes those paths when building.

Or use `read_then_write_serial.sh` at the repository root, which builds the read example and this tool before programming.

## Usage

### Changing FT232R Serial Number

#### Method 1: Using EEPROM Write Example

1. **Disable Kernel Driver:**

   Before using your FTDI device, you need to disable Linux kernel's default `ftdi_sio` driver:

   ```bash
   sudo rmmod ftdi_sio
   sudo rmmod usbserial
   ```

   If the driver is not loaded, these commands may give errors, which is normal.

2. **Connect Device and Determine Port Number:**

   ```bash
   lsusb | grep FTDI
   ```

   Note your device's VID:PID information (usually 0403:6001 for FT232R).

3. **Run Write Program:**

   ```bash
   cd linux-x86_64/examples/EEPROM/write
   sudo ./write 0
   ```

   The `0` parameter selects the first FTDI device. If you have multiple devices, you can change the port number.

   The program:
   - Automatically detects device type
   - Writes "SERTAC-WS1" serial number for FT232R
   - Programs the EEPROM

   **Note:** To change the serial number, edit the line `Data.SerialNumber = "SERTAC-WS1";` in `main.c` and recompile.

#### Method 2: Using Command Line Tool

```bash
cd linux-x86_64
sudo ./ft_eeprom_write_serial NEW-SERIAL-NO
```

This tool:
- Reads current EEPROM contents
- Only changes the serial number
- Preserves other settings

**Example:**
```bash
sudo ./ft_eeprom_write_serial MY-DEVICE-001
```

### Unique Device Nodes with Udev Rules

When using multiple USB-serial cables, you can use udev rules so that each device gets the same unique device node regardless of which USB port it's plugged into.

#### 1. Change Serial Number

Assign a unique serial number to each FTDI device using one of the methods above.

#### 2. Create Udev Rules File

Create or edit the `/etc/udev/rules.d/97-serial-uart.rules` file:

```bash
sudo nano /etc/udev/rules.d/97-serial-uart.rules
```

#### 3. Add Rules

Add a rule for each device. Format:

```
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="SERTAC-WS1", SYMLINK+="serial-apple", RUN+="/usr/bin/logger serial-apple uart inserted or removed"
```

**Parameters:**
- `ATTRS{idVendor}=="0403"`: FTDI's vendor ID
- `ATTRS{idProduct}=="6001"`: FT232R's product ID
- `ATTRS{serial}=="SERTAC-WS1"`: Your device's serial number (the one you wrote to EEPROM)
- `SYMLINK+="serial-apple"`: Name of the symlink to create (you can use any name you want)

**Example Rules File:**

```
# Unique symlinks for FT232R devices
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="SERTAC-WS1", SYMLINK+="serial-apple", RUN+="/usr/bin/logger serial-apple uart inserted or removed"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="B00315WN", SYMLINK+="serial-orange", RUN+="/usr/bin/logger serial-orange uart inserted or removed"

# Other USB-serial devices
SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="serial-at301", RUN+="/usr/bin/logger at301 uart inserted or removed"
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="serial-bl201", RUN+="/usr/bin/logger BL201 uart inserted or removed"
```

#### 4. Reload Udev Rules

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

#### 5. Reconnect Device

Unplug and reconnect the device. Unique symlinks like `/dev/serial-apple` will now be created.

#### 6. Verification

```bash
ls -l /dev/serial-*
```

Output should look like:

```
lrwxrwxrwx 1 root root 7 Dec 10 10:30 /dev/serial-apple -> ttyUSB0
lrwxrwxrwx 1 root root 7 Dec 10 10:31 /dev/serial-orange -> ttyUSB1
```

Now, regardless of which USB port you plug your devices into, `/dev/serial-apple` will always point to the same device.

## Troubleshooting

### Linker: `cannot find -lftd2xx`

- Install **`libftd2xx.so`** from FTDI’s D2XX Linux package (see [Install `libftd2xx.so` on your system](#2-install-libftd2xxso-on-your-system) and the [download table](#1-where-libftd2xxso-comes-from-official-ftdi-d2xx-for-linux)), then `sudo ldconfig`.
- Or run `read_then_write_serial.sh` **without** `FTDI_D2XX_NO_AUTO_DOWNLOAD=1` so it can try the **optional FTDI download** path (see [Optional: automatic libftd2xx download](#optional-automatic-libftd2xx-download)).
- This is **not** satisfied by `apt install libftdi-dev` (different library: libFTDI vs FTDI D2XX).
- Confirm the `.so` architecture with `file` on the installed path and match it to `uname -m`.

### FT_Open() Error

If you get an `FT_Open()` error:

1. Make sure kernel drivers are disabled:
   ```bash
   lsmod | grep ftdi
   sudo rmmod ftdi_sio usbserial
   ```

2. Make sure the device is connected:
   ```bash
   lsusb | grep FTDI
   ```

### Udev Rules Not Working

1. Check rule syntax (commas and quotes are important)
2. Make sure the serial number is correct:
   ```bash
   udevadm info /dev/ttyUSB0 | grep SERIAL
   ```
3. Reload udev rules:
   ```bash
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

### EEPROM Write Error

- Make sure you're running with root privileges (`sudo`)
- Make sure the device's EEPROM is not protected
- Remember that serial number is maximum 16 characters

## References

- [FTDI D2XX Programmer's Guide](https://ftdichip.com/documentation/programming-guides/)
- [FTDI Linux Drivers](https://ftdichip.com/drivers/d2xx-drivers/)
- [Udev Rules Documentation](https://wiki.archlinux.org/title/udev)

## Notes

- These tools are for testing and development purposes only
- EEPROM write operations are irreversible, be careful
- Test before using in production environment
- FTDI device warranty may be voided due to EEPROM modifications
