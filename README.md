# TARPN-Anything: Universal TARPN Node Installation Scripts

**Multi-Platform TARPN Installation for Raspberry Pi and x86/x64 Linux Systems**

[![Platform Support](https://img.shields.io/badge/platform-Raspberry%20Pi%20%7C%20x86%2Fx64-blue)]()
[![OS Support](https://img.shields.io/badge/os-Debian%20%7C%20Ubuntu%20%7C%20Raspbian-green)]()
[![License](https://img.shields.io/badge/license-See%20Original%20TARPN-lightgrey)]()

---

## Portability layer (any user name, any CPU)

The original TARPN scripts assume user `pi`, home `/home/pi` and a 32-bit ARM Raspberry Pi.
Tarpn-Anything handles this with `tarpn_portable.sh` (installed to `/usr/local/sbin`):

- **Any user / any home:** the installer records who you are in `/usr/local/etc/tarpn_user.conf`.
  Every script downloaded from tarpn.net is rewritten on download (`/home/pi` -> your home,
  `chown pi` -> your user, ...). Systemd services run as root, so real paths are written in, not `$HOME`.
- **Any CPU:** 32-bit ARM runs everything natively. 64-bit ARM gets the armhf libraries; x86/x86_64
  gets QEMU user-mode emulation for the ARM-only helper programs plus G8BPQ's Intel LinBPQ.
- **Repo can live anywhere:** scripts find their own folder; `tarpn` / `tarpn_start2.sh` are *copied*,
  not moved, so the repo stays complete.
- **Disabled on purpose:** `tarpn update` (always) and `tarpn updateapps` (non-32-bit-ARM) would
  re-install the Raspberry-Pi-only upstream versions.
- **QtTermTCP:** installed for every CPU - the Pi build on ARM, G8BPQ's native Intel build on x86/x86_64.
- **Known limits:** TARPN HOME ships as Python 3.9 bytecode and needs `python3.9`; the Pi GPIO
  control-panel service is installed only on a Raspberry Pi.

---

## Table of Contents

- [Overview](#overview)
- [What's New](#whats-new)
- [Platform Support](#platform-support)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation Guide](#installation-guide)
  - [Raspberry Pi Installation](#raspberry-pi-installation)
  - [x86/x64 Installation](#x8664-installation)
- [Hardware Requirements](#hardware-requirements)
- [Changes from Original Scripts](#changes-from-original-scripts)
- [Architecture Improvements](#architecture-improvements)
- [Troubleshooting](#troubleshooting)
- [Testing and Validation](#testing-and-validation)
- [Contributing](#contributing)
- [Credits](#credits)

---

## Overview

**TARPN-Anything** is an enhanced version of the original TARPN (Tucson Amateur Packet Radio Network) installation scripts. These scripts have been completely refactored to work on **any Linux-based system**, not just Raspberry Pi, while maintaining 100% backward compatibility with existing Raspberry Pi installations.

The original TARPN scripts were designed exclusively for Raspberry Pi with the hardcoded `pi` user. This project removes all platform-specific limitations and adds intelligent hardware detection, making TARPN accessible on a wide range of Linux systems.

---

## What's New

### ✨ Universal Platform Support
- **Works on any user account** - no longer limited to the `pi` user
- **Works on any Debian-based Linux** - Raspberry Pi, Debian, Ubuntu, Linux Mint, etc.
- **Automatic hardware detection** - intelligently adapts to your system
- **100% backward compatible** - existing Raspberry Pi installations unaffected

### 🔧 Major Enhancements (v2.0)

#### 1. **Multi-Platform Compatibility**
- Removed hardcoded `pi` user - works with any username
- Removed hardcoded `/home/pi` paths - uses `$HOME` and `$USER` variables
- Added OS detection for any Debian-based distribution
- Graceful handling of platform-specific features

#### 2. **Intelligent Hardware Detection**
- **Serial Port Auto-Detection**
  - Scans for all serial devices (USB, built-in, Bluetooth)
  - Identifies FTDI, CH340, Prolific, and other USB adapters
  - Shows vendor, model, and serial number
  - Displays port availability status
  
- **Temperature Monitoring**
  - Raspberry Pi: `vcgencmd` support
  - x86/x64: `lm-sensors` with full chipset/CPU monitoring
  - Generic: Thermal zone sensors
  - Multiple sensor support with detailed output
  
- **Audio Device Detection**
  - Auto-detects all ALSA playback devices
  - Identifies default audio card
  - Works with USB audio, HDMI audio, built-in audio
  
- **Network Interface Discovery**
  - Detects all network interfaces (wired and wireless)
  - Shows interface status, MAC, IP addresses
  - Identifies Wi-Fi connections with SSID
  
- **System Capabilities**
  - Platform identification (Raspberry Pi vs. Generic Linux)
  - CPU model, core count, architecture
  - Motherboard and BIOS information (x86/x64)
  - Memory configuration

#### 3. **Enhanced System Information**
- Comprehensive hardware inventory in `tarpn sysinfo`
- Platform-appropriate monitoring tools
- Multi-method temperature monitoring
- Detailed serial port information
- USB device enumeration

#### 4. **x86/x64 Optimizations**
- Automatic installation of `lm-sensors` for temperature monitoring
- Enhanced CPU/motherboard information display
- USB serial adapter support and identification
- Platform-specific package installation

---

## Platform Support

### Tested and Supported Platforms

| Platform | Architecture | OS | Status |
|----------|--------------|-----|--------|
| Raspberry Pi (All models) | ARM/ARM64 | Raspberry Pi OS | ✅ Fully Supported |
| Raspberry Pi Zero/2W | ARM | Raspberry Pi OS | ✅ Fully Supported |
| Generic PC/Server | x86_64 | Debian 11+ | ✅ Fully Supported |
| Generic PC/Server | x86_64 | Ubuntu 20.04+ | ✅ Fully Supported |
| Generic PC/Server | x86_64 | Linux Mint 20+ | ✅ Fully Supported |
| Virtual Machines | x86_64 | Any Debian-based | ✅ Supported |

### Minimum System Requirements

- **CPU**: Any (ARM, x86, x86_64)
- **RAM**: 512MB minimum, 1GB+ recommended
- **Disk**: 4GB minimum free space, 8GB+ recommended
- **OS**: Debian-based Linux (Debian 9+, Ubuntu 18.04+, Raspbian)
- **Network**: Internet connection required during installation
- **Package Manager**: apt/apt-get (Debian-based)

---

## Features

### Core TARPN Features (Preserved)
- ✅ LinBPQ installation and configuration
- ✅ NinoTNC support
- ✅ TARPN Home web interface
- ✅ Direwolf support
- ✅ Packet radio node operation
- ✅ Automatic service configuration
- ✅ All original TARPN functionality

### New Multi-Platform Features
- ✅ Universal user support (not just `pi`)
- ✅ x86/x64 system support
- ✅ Automatic hardware detection
- ✅ Enhanced temperature monitoring
- ✅ Serial port auto-discovery
- ✅ Audio device auto-configuration
- ✅ Network interface smart detection
- ✅ Platform-specific optimizations
- ✅ Graceful feature degradation
- ✅ Comprehensive system information

---

## Prerequisites

### Required Software (Auto-installed during setup)
The installation scripts will automatically install all required packages. However, you should start with a fresh, minimal installation of:

- Debian 11+ (Bullseye or newer) **OR**
- Ubuntu 20.04+ **OR**
- Raspberry Pi OS (any recent version)

### Before You Begin

1. **Fresh OS Installation**
   - Start with a clean, freshly installed OS
   - Complete initial OS setup (user creation, network configuration)
   - Ensure system is up to date:
     ```bash
     sudo apt-get update
     sudo apt-get upgrade
     ```

2. **Network Connectivity**
   - Active internet connection required
   - Able to access GitHub and package repositories
   - Firewall allows outbound HTTP/HTTPS

3. **User Account**
   - Can be any username (not limited to `pi`)
   - Must have sudo privileges
   - SSH access recommended for remote installation

4. **Hardware Access**
   - If using serial ports, connect USB serial adapters before installation
   - For Raspberry Pi, ensure GPIO is accessible (if using)
   - Audio device connected if using audio features

---

## Installation Guide

### Quick Start (Any Platform)

```bash
# 1. Clone the repository
cd ~
git clone https://github.com/yourusername/Tarpn-Anything.git
cd Tarpn-Anything

# 2. Make scripts executable
chmod +x tarpn_start1.sh

# 3. Run the first installation script
./tarpn_start1.sh
```

The installation will:
- Detect your hardware automatically
- Install platform-appropriate packages
- Configure all necessary services
- Reboot when needed (follow prompts)

---

### Raspberry Pi Installation

#### Step 1: Prepare Your Raspberry Pi

1. **Download Raspberry Pi OS**
   - Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
   - Select "Raspberry Pi OS Lite" or "Raspberry Pi OS with desktop"
   - Flash to SD card (8GB minimum, 16GB+ recommended)

2. **Initial Boot and Setup**
   ```bash
   # SSH into your Raspberry Pi (or use terminal directly)
   ssh yourusername@raspberrypi.local
   
   # Update system
   sudo apt-get update
   sudo apt-get upgrade -y
   sudo reboot
   ```

#### Step 2: Clone and Run Installation

```bash
# After reboot, SSH back in
ssh yourusername@raspberrypi.local

# Clone the repository
cd ~
git clone https://github.com/yourusername/Tarpn-Anything.git
cd Tarpn-Anything

# Make the first script executable
chmod +x tarpn_start1.sh

# Run the installation
./tarpn_start1.sh
```

#### Step 3: Monitor Installation Progress

The script will:
1. ✅ Detect Raspberry Pi hardware
2. ✅ Verify OS version (bypasses strict version check)
3. ✅ Display detected hardware capabilities
4. ✅ Download and execute installation script
5. ✅ Perform hardware detection:
   - Serial ports (ttyAMA0, USB adapters)
   - Temperature sensors (vcgencmd)
   - Audio devices
   - Network interfaces
6. ✅ Install all required packages
7. ✅ Configure TARPN services
8. ✅ Request reboot

#### Step 4: Continue After Reboot

```bash
# After automatic reboot, SSH back in
ssh yourusername@raspberrypi.local

# The second script should run automatically
# If not, run manually:
/usr/local/sbin/tarpn_start2.sh      # run as your normal user, NOT with sudo
```

#### Step 5: Final Reboot and Verification

```bash
# After final reboot
ssh yourusername@raspberrypi.local

# Verify installation
tarpn sysinfo

# Check TARPN services
tarpn status
```

---

### x86/x64 Installation

#### Step 1: Prepare Your System

1. **Install Debian or Ubuntu**
   - Fresh installation of Debian 11+, Ubuntu 20.04+, or derivative
   - Server or Desktop version both work
   - Ensure network connectivity
   - Create a user account with sudo privileges

2. **Update System**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade -y
   sudo reboot
   ```

#### Step 2: Install Required Base Packages

```bash
# Install git if not present
sudo apt-get install -y git

# Install basic build tools (optional but recommended)
sudo apt-get install -y build-essential
```

#### Step 3: Clone and Run Installation

```bash
# Clone the repository
cd ~
git clone https://github.com/yourusername/Tarpn-Anything.git
cd Tarpn-Anything

# Make the first script executable
chmod +x tarpn_start1.sh

# Run the installation
./tarpn_start1.sh
```

#### Step 4: Monitor Hardware Detection

The installation will automatically detect:

```
##############################################################################
#### HARDWARE DETECTION - Detecting capabilities for optimal configuration
##############################################################################

##### Detecting system architecture and capabilities...
  Platform: Generic Linux (x86_64)
  System: Dell Inc. OptiPlex 7050
  CPU: Intel(R) Core(TM) i7-7700 CPU @ 3.60GHz
  Memory: 16Gi

##### Detecting serial ports on this system...
  Found: /dev/ttyUSB0 (FTDI FT232R USB UART)
  Serial ports saved to /tmp/tarpn_detected_serial_ports.txt

##### Detecting temperature monitoring capabilities...
  Generic thermal zones: Found 3 zone(s)
    - x86_pkg_temp
    - acpitz
    - pch_skylake
  Note: Install lm-sensors for enhanced temperature monitoring (optional)

##### Detecting audio devices...
  Available audio playback devices:
  card 0: PCH [HDA Intel PCH], device 0: ALC662 rev3 Analog

##### Detecting network interfaces...
  Interface: enp3s0
    State: UP
    MAC: 00:1a:2b:3c:4d:5e
    IP: 192.168.1.100
    Type: Wired
```

#### Step 5: Platform-Specific Package Installation

The script will automatically install x86/x64-specific tools:

```bash
##### Install platform-specific monitoring tools
##### Detected x86/x64 system - installing lm-sensors for temperature monitoring
##### Installing usbutils for USB device detection
```

**After installation, configure lm-sensors (optional but recommended):**

```bash
sudo sensors-detect
```

Press ENTER to accept defaults, then add modules to load at boot.

#### Step 6: Connect Serial Hardware

For TARPN packet radio operation, you'll need a TNC (Terminal Node Controller) or USB serial adapter:

**Recommended TNCs and Adapters:**
- **NinoTNC** ⭐ **Best Choice for TARPN** - Purpose-built TNC for packet radio with USB interface
- **FTDI FT232R** - Reliable USB serial adapter, excellent Linux support
- **FTDI FT232H** - High-speed version for advanced applications
- **CH340/CH341** - Budget-friendly option, works well
- **Prolific PL2303** - Older but compatible

**Connect your adapter:**
1. Plug in USB serial adapter
2. Verify detection:
   ```bash
   lsusb
   dmesg | grep tty
   ls /dev/ttyUSB*
   ```

3. Check detection in TARPN:
   ```bash
   tarpn sysinfo | grep "Serial Ports" -A 20
   ```

#### Step 7: Continue After Reboot

```bash
# After automatic reboot
# The second script should run automatically
# If not, run manually:
/usr/local/sbin/tarpn_start2.sh      # run as your normal user, NOT with sudo
```

#### Step 8: Verify Installation

```bash
# Check system information
tarpn sysinfo

# Verify temperature monitoring
tarpn sysinfo | grep -A 20 "Temperature"

# Check serial ports
tarpn sysinfo | grep -A 20 "Serial Ports"

# Verify TARPN services
tarpn status
```

---

## Hardware Requirements

### Raspberry Pi

| Component | Requirement | Notes |
|-----------|-------------|-------|
| **Model** | Any Raspberry Pi | Pi Zero, 2, 3, 4, 5 all supported |
| **RAM** | 512MB minimum | 1GB+ recommended for better performance |
| **Storage** | 8GB SD card | 16GB+ recommended |
| **TNC/Serial** | NinoTNC, built-in UART, or USB adapter | NinoTNC recommended, GPIO serial or USB-to-serial |
| **Audio** | Built-in audio | BCM2835 audio automatically configured |
| **Network** | Ethernet or Wi-Fi | Required for installation |

### x86/x64 Systems

| Component | Requirement | Notes |
|-----------|-------------|-------|
| **CPU** | Any x86/x64 | Celeron, Pentium, Core i3/i5/i7, AMD Ryzen, etc. |
| **RAM** | 1GB minimum | 2GB+ recommended |
| **Storage** | 8GB minimum | HDD or SSD |
| **TNC/Serial** | NinoTNC or USB serial adapter | NinoTNC recommended, FTDI FT232R for other TNCs |
| **Audio** | Any ALSA device | Built-in, USB, or PCI audio card |
| **Network** | Ethernet or Wi-Fi | Required for installation |

### TNCs and Serial Adapters

**Recommended Hardware for TARPN Packet Radio:**

#### 1. **NinoTNC** ⭐ **Best Choice for TARPN**
   - Purpose-built TNC designed specifically for packet radio
   - USB interface with built-in KISS mode
   - Excellent performance and reliability
   - Native TARPN support
   - Open-source hardware design
   - Available from various vendors
   - ~$60-80
   - **Highly recommended** for new TARPN installations

#### 2. **FTDI FT232R-based USB Serial Adapters**
   - Excellent Linux support with native kernel drivers
   - Reliable and widely compatible
   - Use with external modems or TNCs
   - Wide availability
   - ~$15-25

#### 3. **FTDI FT232H**
   - High-speed version of FT232R
   - Multiple protocol support
   - Best for advanced applications
   - ~$20-30

#### 4. **CH340/CH341-based Adapters**
   - Budget-friendly option
   - Good Linux kernel support
   - Works well for TARPN
   - Widely available
   - ~$5-10

#### 5. **Prolific PL2303**
   - Older chipset but compatible
   - Widely available
   - Acceptable performance
   - ~$5-15

**Other Compatible TNCs:**
- DireWolf software TNC (soundcard-based)
- KISS-mode TNCs with serial interface
- Any TNC that supports KISS protocol

**Not Recommended:**
- Generic no-name adapters (may use counterfeit chips)
- Adapters without clear chipset identification
- Non-KISS mode TNCs without serial interface

---

## Changes from Original Scripts

### 1. User Independence

**Before:**
```bash
/home/pi/bpq/linbpq
```

**After:**
```bash
$HOME/bpq/linbpq
```

**Impact:** Works with any username, not just `pi`

---

### 2. Universal Variable Usage

**Before:**
```bash
if [ $(whoami) != "pi" ]; then
    echo "ERROR: Must run as pi user"
    exit 1
fi
```

**After:**
```bash
# Removed - works with any user with sudo privileges
```

**Impact:** No user restrictions

---

### 3. Operating System Flexibility

**Before:**
```bash
grep "11 (bullseye)" /etc/*-release || exit 1
```

**After:**
```bash
# Check for Debian-based distribution (apt package manager)
if command -v apt-get &> /dev/null; then
    # Accept Debian, Ubuntu, Raspbian, and derivatives
fi
```

**Impact:** Works on Debian 9+, Ubuntu 18.04+, and all derivatives

---

### 4. Raspberry Pi Specific Features Made Conditional

**Before:**
```bash
vcgencmd measure_temp
```

**After:**
```bash
if command -v vcgencmd &> /dev/null; then
    vcgencmd measure_temp
elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    # Use generic thermal zones
elif command -v sensors &> /dev/null; then
    # Use lm-sensors on x86/x64
fi
```

**Impact:** Graceful fallback to platform-appropriate alternatives

---

### 5. Boot Configuration

**Before:**
```bash
sed -i "s^enable_uart=0^enable_uart=1^" /boot/config.txt
```

**After:**
```bash
if [ -f /boot/config.txt ]; then
    # Raspberry Pi specific configuration
else
    # Skip on non-RPi systems
fi
```

**Impact:** No errors on x86/x64 systems

---

### 6. GPIO Operations

**Before:**
```bash
echo "0" > /sys/class/gpio/gpio9/value
```

**After:**
```bash
if [ -d /sys/class/gpio ]; then
    echo "0" > /sys/class/gpio/gpio9/value 2>/dev/null || true
fi
```

**Impact:** Optional GPIO, no failures on systems without GPIO

---

### 7. BCM-Specific Modules

**Before:**
```bash
sudo modprobe snd_bcm2835
```

**After:**
```bash
if lsmod | grep -q "snd_bcm2835" || modinfo snd_bcm2835 &>/dev/null; then
    sudo modprobe snd_bcm2835 2>/dev/null || true
fi
```

**Impact:** Only loads on Raspberry Pi, skips on other systems

---

### 8. Serial Port Configuration

**Before:**
```bash
sudo systemctl stop serial-getty@ttyAMA0.service
```

**After:**
```bash
if [ -f /boot/config.txt ]; then
    # Raspberry Pi serial configuration
else
    # Generic serial port configuration for x86/x64
    for port in ttyS0 ttyUSB0 ttyACM0; do
        sudo systemctl stop serial-getty@${port}.service 2>/dev/null || true
    done
fi
```

**Impact:** Configures appropriate serial ports for platform

---

## Architecture Improvements

### Hardware Detection System

**New Component:** `tarpn_start1dl.sh:218-387`

Five intelligent detection functions run during installation:

1. **`detect_serial_ports()`**
   - Scans `/dev/tty*` for all serial devices
   - Queries `udevadm` for USB device information
   - Saves configuration to `/tmp/tarpn_detected_serial_ports.txt`

2. **`detect_audio_devices()`**
   - Uses `aplay -l` to enumerate ALSA devices
   - Identifies default playback card
   - Saves to `/tmp/tarpn_detected_audio_card.txt`

3. **`detect_temperature_sensors()`**
   - Checks for vcgencmd (RPi)
   - Scans thermal zones (generic)
   - Detects lm-sensors (x86/x64)
   - Saves method to `/tmp/tarpn_temp_method.txt`

4. **`detect_system_capabilities()`**
   - Reads `/proc/device-tree/model` (RPi)
   - Reads DMI information (x86/x64)
   - Extracts CPU and memory info
   - Saves to `/tmp/tarpn_system_info.txt`

5. **`detect_network_interfaces()`**
   - Uses `ip` command for interface discovery
   - Detects wireless vs. wired
   - Shows status, MAC, IP, SSID

### Enhanced System Information

**Enhanced Component:** `tarpn` sysinfo command

**New Sections:**
- **System Architecture & CPU Info** - Platform-appropriate details
- **Enhanced Temperature Monitoring** - Multi-method with fallbacks
- **Serial Port Information** - Full USB device details
- **Improved Network Display** - Comprehensive interface info

### Platform-Specific Optimizations

**x86/x64 Enhancements:**
```bash
# Auto-install monitoring tools
if [ ! -f /proc/device-tree/model ]; then
    sudo apt-get install -y lm-sensors
    sudo apt-get install -y usbutils
fi
```

**Raspberry Pi Preservation:**
```bash
# RPi-specific features still fully functional
if grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    # GPIO, vcgencmd, boot config all preserved
fi
```

---

## Troubleshooting

### Common Issues

#### 1. "No serial ports detected"

**Problem:** TARPN can't find serial ports for TNC connection

**Solution for Raspberry Pi:**
```bash
# Check if UART is enabled
ls /dev/ttyAMA* /dev/serial*

# If missing, enable UART in raspi-config
sudo raspi-config
# Navigate to: Interface Options -> Serial Port -> Enable
```

**Solution for x86/x64:**
```bash
# Check if NinoTNC or USB serial adapter is connected
lsusb | grep -i "serial\|ftdi\|ch340\|prolific\|nino"

# Check kernel detected device
dmesg | grep tty

# List available ports
ls /dev/ttyUSB* /dev/ttyACM*

# Check permissions
sudo usermod -a -G dialout $USER
# Log out and back in for group change to take effect
```

**For NinoTNC specifically:**
```bash
# NinoTNC typically appears as /dev/ttyACM0 or /dev/ttyUSB0
ls -l /dev/ttyACM* /dev/ttyUSB*

# Verify it's recognized
lsusb | grep -i "ftdi\|arduino\|atmel"

# Check dmesg for NinoTNC detection
dmesg | tail -20
```

---

#### 2. "Temperature monitoring not available"

**Problem:** Can't read CPU temperature

**Solution for x86/x64:**
```bash
# Install lm-sensors
sudo apt-get install -y lm-sensors

# Run detection
sudo sensors-detect

# Answer YES to all questions
# Add suggested modules to /etc/modules

# Test
sensors
```

**Solution for Raspberry Pi:**
```bash
# Test vcgencmd
vcgencmd measure_temp

# If not working, update firmware
sudo apt-get update
sudo apt-get upgrade
sudo reboot
```

---

#### 3. "Audio device not found"

**Problem:** Audio configuration fails

**Solution:**
```bash
# List audio devices
aplay -l

# If no devices found, check if ALSA is installed
sudo apt-get install -y alsa-utils

# Test audio
speaker-test -t wav -c 2

# Check if user is in audio group
groups | grep audio
sudo usermod -a -G audio $USER
```

---

#### 4. "Platform checks failed"

**Problem:** OS version check rejects your distribution

**Solution:**
```bash
# Create bypass file
sudo touch /usr/local/etc/bypass-platform-checks.txt

# Re-run installation
./tarpn_start1.sh
```

---

#### 5. "Permission denied" errors

**Problem:** User doesn't have necessary permissions

**Solution:**
```bash
# Add user to necessary groups
sudo usermod -a -G dialout,audio,video,gpio $USER

# Verify sudo access
sudo -v

# Log out and log back in
logout
```

---

#### 6. Serial port "/dev/ttyUSB0 in use"

**Problem:** Serial port shows as "IN USE" in sysinfo

**Solution:**
```bash
# Check what's using the port
sudo fuser /dev/ttyUSB0

# Check for conflicting services
sudo systemctl list-units | grep serial

# Stop serial console if needed
sudo systemctl stop serial-getty@ttyUSB0.service
sudo systemctl disable serial-getty@ttyUSB0.service
```

---

### Debug Commands

**Check Installation Status:**
```bash
# View installation logs
tail -f /var/log/tarpn_startstop.log

# Check service status
tarpn status

# View system info
tarpn sysinfo
```

**Check Hardware Detection:**
```bash
# View detected serial ports
cat /tmp/tarpn_detected_serial_ports.txt

# View system info
cat /tmp/tarpn_system_info.txt

# View temperature method
cat /tmp/tarpn_temp_method.txt

# View audio card
cat /tmp/tarpn_detected_audio_card.txt
```

**Manual Hardware Checks:**
```bash
# Serial ports
ls -l /dev/tty{USB,ACM,S,AMA}* 2>/dev/null

# USB devices
lsusb -v | grep -i "serial\|ftdi"

# Temperature sensors
cat /sys/class/thermal/thermal_zone*/temp
sensors

# Audio devices
aplay -l
amixer scontrols

# Network interfaces
ip link show
ip addr show
```

---

## Testing and Validation

### Pre-Installation Testing

Before running installation, verify your environment:

```bash
# Check OS compatibility
cat /etc/*-release | grep -E "ID=|VERSION="

# Verify internet connectivity
ping -c 4 github.com

# Check sudo access
sudo -v

# Verify disk space
df -h

# Check for previous installations
ls /usr/local/sbin/tarpn* 2>/dev/null
```

---

### Post-Installation Validation

After installation completes:

#### 1. **Verify Services**
```bash
tarpn status
# Should show TARPN node running
```

#### 2. **Check System Information**
```bash
tarpn sysinfo
# Review all sections for accuracy
```

#### 3. **Validate Serial Ports**
```bash
tarpn sysinfo | grep -A 20 "Serial Ports"
# Verify your TNC port is listed and available
```

#### 4. **Test Temperature Monitoring**
```bash
tarpn sysinfo | grep -A 15 "Temperature"
# Should show temperature readings
```

#### 5. **Check Network Configuration**
```bash
tarpn sysinfo | grep -A 20 "Network"
# Verify interfaces are detected
```

#### 6. **Verify Audio** (if using)
```bash
# Test audio playback
speaker-test -t wav -c 2 -l 1
```

#### 7. **Test TARPN Home** (if configured)
```bash
# Check if web interface is running
curl http://localhost:8080
# Or access from browser: http://your-ip:8080
```

---

### Regression Testing (for Raspberry Pi)

To ensure backward compatibility on Raspberry Pi:

```bash
# 1. Verify GPIO (if using)
gpio -v

# 2. Check vcgencmd
vcgencmd measure_temp
vcgencmd version

# 3. Verify serial port
ls /dev/ttyAMA0 /dev/serial0

# 4. Check boot configuration
grep enable_uart /boot/config.txt

# 5. Test all TARPN commands
tarpn help
tarpn status
tarpn sysinfo
tarpn version
```

---

## Contributing

Contributions are welcome! Here's how you can help:

### Reporting Issues

1. **Check existing issues** on GitHub
2. **Provide detailed information:**
   - Platform (Raspberry Pi model or x86/x64 specs)
   - OS version (`cat /etc/*-release`)
   - Error messages
   - Output of `tarpn sysinfo`
   - Installation logs

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Test on both Raspberry Pi AND x86/x64 if possible
5. Ensure backward compatibility
6. Submit pull request with detailed description

### Testing New Features

We especially need testing on:
- Different x86/x64 hardware configurations
- Various USB serial adapters
- Different Debian-based distributions
- ARM64 platforms

---

## Credits

### Original TARPN Scripts
- **Original Author:** Tadd Torborg (KA2DEW)
- **Copyright:** 2014-2025 Tadd Torborg
- **Original Purpose:** Raspberry Pi TARPN node installation

### TARPN-Anything Enhancements
- **Multi-Platform Refactoring:** 2025
- **Contributors:** Community contributors (see GitHub)
- **Purpose:** Universal Linux TARPN installation

### TARPN Project
- **Website:** [tarpn.net](http://tarpn.net)
- **Documentation:** TARPN Wiki and Forums
- **Community:** TARPN Groups.io mailing list

---

## License

This project maintains the original copyright and licensing from the TARPN project by Tadd Torborg (KA2DEW). All modifications and enhancements are provided under the same terms as the original scripts.

**Please leave copyright notices intact and document any changes made.**

---

## Support and Documentation

- **TARPN Website:** [http://tarpn.net](http://tarpn.net)
- **TARPN Groups.io:** [https://groups.io/g/tarpn](https://groups.io/g/tarpn)
- **GitHub Issues:** Report bugs and request features
- **Wiki:** Detailed configuration and troubleshooting guides

---

## Version History

### v2.0 (2025) - Multi-Platform Release
- ✅ Added x86/x64 support
- ✅ Removed user restrictions (`pi` user)
- ✅ Added intelligent hardware detection
- ✅ Enhanced temperature monitoring
- ✅ Serial port auto-discovery
- ✅ Audio device auto-detection
- ✅ Network interface smart detection
- ✅ Platform-specific optimizations
- ✅ Comprehensive system information
- ✅ 100% backward compatible with Raspberry Pi

### v1.x (2014-2024) - Original TARPN Scripts
- Original Raspberry Pi installation scripts
- Hardcoded for `pi` user
- Raspberry Pi OS (Raspbian) only
- All core TARPN functionality

---

## Quick Reference Card

### Essential Commands

```bash
# Installation
./tarpn_start1.sh              # Start installation

# System Information
tarpn sysinfo                  # Full system hardware info
tarpn status                   # Check TARPN services
tarpn version                  # Show version info

# Hardware Detection Files
cat /tmp/tarpn_detected_serial_ports.txt    # Serial ports
cat /tmp/tarpn_system_info.txt              # System capabilities
cat /tmp/tarpn_temp_method.txt              # Temperature method
cat /tmp/tarpn_detected_audio_card.txt      # Audio card

# Troubleshooting
tail -f /var/log/tarpn_startstop.log       # View logs
sudo systemctl status tarpn                 # Service status
lsusb                                       # Check USB devices
sensors                                     # Check temperature (x86/x64)
```

### Key Files and Locations

| File/Directory | Purpose |
|----------------|---------|
| `~/Tarpn-Anything/` | Installation scripts location |
| `~/bpq/` | BPQ installation directory |
| `/usr/local/sbin/tarpn` | Main TARPN command |
| `/var/log/tarpn_startstop.log` | Installation/startup log |
| `/tmp/tarpn_*.txt` | Hardware detection cache |
| `/usr/local/etc/bypass-platform-checks.txt` | Platform check bypass |

---

**Happy TARPN node building! 73!**

---

*For questions, support, or to contribute, visit the GitHub repository or join the TARPN mailing list.*
