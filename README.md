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

- Linux (x86_64)
- GCC compiler
- libftd2xx library (included in this repository)
- Root privileges (for EEPROM writing)

## Installation and Build

### 1. Library Installation

Install the libftd2xx library on your system:

```bash
cd linux-x86_64
sudo cp libftd2xx.so.1.4.33 /usr/local/lib/
sudo ln -sf /usr/local/lib/libftd2xx.so.1.4.33 /usr/local/lib/libftd2xx.so
sudo ldconfig
```

### 2. EEPROM Write Example Build

```bash
cd linux-x86_64/examples/EEPROM/write
make
```

This command creates an executable named `write`.

### 3. Command Line Serial Number Tool Build

```bash
cd linux-x86_64
gcc -o ft_eeprom_write_serial ft_eeprom_write_serial.c -lftd2xx -L/usr/local/lib -Wl,-rpath /usr/local/lib
```

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
