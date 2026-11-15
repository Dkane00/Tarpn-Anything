# TARPN Installation Scripts - Flow Documentation

## Overview
This document maps the complete flow of all installation scripts, showing what each script does, which scripts call other scripts, and what gets installed where on your machine.

---

## Script Execution Order

```
1. tarpn_start1.sh
   ├── Downloads and validates source URL
   ├── Downloads tarpnget.sh and sleep_with_count.sh
   └── Calls tarpn_start1dl.sh
       └── 2. tarpn_start1dl.sh
           ├── Downloads and installs core system components
           ├── Prepares tarpn_start2.sh
           └── Reboots system
               └── 3. tarpn_start2.sh (runs after reboot)
                   ├── Installs services and additional applications
                   └── Final system reboot
```

After installation, the main runtime script is:
- **`tarpn`** - Main command-line interface for managing TARPN

---

## Detailed Script Analysis

### 1. `tarpn_start1.sh`
**Location**: `<repo folder>/tarpn_start1.sh` (the repo can be cloned anywhere)  
**Version**: BULLSEYE 022

#### What It Does:
- **Environment Validation**
  - Finds its own folder (`TARPN_SRC_DIR`) and checks every repo file is present (including `tarpn_portable.sh`)
  - Records the installing user, their home and the CPU type in `/usr/local/etc/tarpn_user.conf` (any user name works; refuses to run as root)
  - Creates bypass file for platform checks: `/usr/local/etc/bypass-platform-checks.txt`
  - Checks for Debian-based Linux distribution
  - Validates sudo access by creating `/usr/local/etc/sudoerstest.txt`

- **Source URL Configuration**
  - Sets `SOURCE_URL="https://tarpn.net/bullseye2021"`
  - Saves to `/usr/local/sbin/source_url.txt`

- **Downloads Core Utilities**
  - Downloads `tarpnget.sh` → installs to `/usr/local/sbin/tarpnget.sh`
  - Downloads `sleep_with_count.sh` → installs to `/usr/local/sbin/sleep_with_count.sh`
  - Copies `tarpn_portable.sh` to `/usr/local/sbin/` and appends a line to `tarpnget.sh` that loads it, so every later download is rewritten for this user (`/home/pi` → real home, `pi` → real user)

#### What It Calls:
- `./tarpn_start1dl.sh` (expects this file in the same directory)

#### What Gets Installed:
| File | Source | Destination | Purpose |
|------|--------|-------------|---------|
| `source_url.txt` | Generated | `/usr/local/sbin/source_url.txt` | Stores download URL |
| `tarpnget.sh` | Web | `/usr/local/sbin/tarpnget.sh` | File download utility |
| `sleep_with_count.sh` | Web | `/usr/local/sbin/sleep_with_count.sh` | Sleep countdown utility |
| `sudoerstest.txt` | Generated | `/usr/local/etc/sudoerstest.txt` | Sudo access validation |
| `tarpn_portable.sh` | Repo | `/usr/local/sbin/tarpn_portable.sh` | User/home/CPU portability layer |
| `tarpn_user.conf` | Generated | `/usr/local/etc/tarpn_user.conf` | Installing user, home, group |
| `bypass-platform-checks.txt` | Generated | `/usr/local/etc/bypass-platform-checks.txt` | Platform check bypass flag |

---

### 2. `tarpn_start1dl.sh`
**Location**: `<repo folder>/tarpn_start1dl.sh`  
**Version**: BULLSEYE 021

#### What It Does:
- **Hardware Detection**
  - Detects serial ports (ttyUSB*, ttyACM*, etc.)
  - Detects audio devices
  - Detects temperature sensors
  - Detects network interfaces
  - Saves detection results to `/tmp/tarpn_*.txt` files

- **System Initialization**
  - Creates timestamp: `/usr/local/sbin/tarpn_start1dl_starttime.txt`
  - Creates multiple log files in `/var/log/`
  - Configures serial ports (disables getty services)
  - Modifies boot configuration (RPi specific)

- **Package Installation** (via apt-get)
  - zip, ftp
  - iputils-ping
  - screen
  - libcap2-bin, libpcap0.8, libpcap-dev
  - minicom, conspy
  - telnet, vim

- **BPQ Node Installation**
  - Creates `~/bpq` directory
  - Downloads and installs LinBPQ (`bpq_6_0_21_40_mar_2021.zip`)
  - Downloads configuration files (boilerplate.cfg, chatconfig.cfg)
  - Installs QtTermTCP terminal program
  - Downloads ring tones for audio notifications

- **TARPN Home Installation**
  - Downloads and installs TARPN Home web application
  - Installs Python dependencies (tornado, configparser, telnetlib3)
  - Creates home service configuration

- **Neighbor Port Association**
  - Downloads and compiles neighbor port association application
  - Installs to `/usr/local/sbin/`

#### What It Calls:
- Prepares `/usr/local/sbin/tarpn_start2.sh` for next boot

#### What Gets Installed:

**Log Files Created** (all in `/var/log/`):
- `tarpn_startstop.log`
- `tarpn_command.log`
- `tarpn_neighbor_port_association.log`
- `tarpn_rx_tarpnstat_service.log`
- `tarpn_service.log`
- `tarpn_home.log`
- `tarpn_linkstatus.log`
- `tarpn_runbpq.log`
- `tarpn_home_webapp_copylog.log`
- `tarpn_ninotnc_getall.log`
- `tarpn_control_panel.log`
- `tarpn_home_runtime.log`
- `tarpn_tarpnstat.log`

**BPQ Node Files**:
| File | Source | Destination | Purpose |
|------|--------|-------------|---------|
| `linbpq` | Web (zip) | `~/bpq/linbpq` | Main BPQ node executable |
| `HTMLPages/` | Web (zip) | `~/bpq/HTML/` | Web interface files |
| `boilerplate.cfg` | Web | `~/bpq/boilerplate.cfg` | BPQ config template |
| `chatconfig.cfg` | Web | `~/bpq/chatconfig.cfg` | Chat service config |
| `configure_node_ini.sh` | Web | `~/bpq/configure_node_ini.sh` | Configuration script |
| `make_local_bpq.sh` | Web | `~/bpq/make_local_bpq.sh` | BPQ builder script |

**TARPN Core Scripts**:
| File | Source | Destination | Purpose |
|------|--------|-------------|---------|
| `runbpq.sh` | Web | `/usr/local/sbin/runbpq.sh` | BPQ node launcher |
| `test_internet.sh` | Web | `/usr/local/sbin/test_internet.sh` | Internet connectivity test |
| `tarpn` | Local | `/usr/local/sbin/tarpn` | Main TARPN CLI command |
| `tarpn_background.sh` | Web | `/usr/local/sbin/tarpn_background.sh` | Background service runner |

**Terminal Programs**:
| File | Source | Destination | Purpose |
|------|--------|-------------|---------|
| `piminicom` | Web (zip) | `~/minicom/piminicom` | Modified minicom |
| `minicom.scr` | Web | `~/minicom/minicom.scr` | Minicom script |
| `qt-term` | Web | `~/Desktop/qt-term` | Qt-based terminal |
| `QtTermTCP.ini` | Web | `~/Desktop/QtTermTCP.ini` | Terminal config |

**TARPN Home (Web App)**:
| File | Source | Destination | Purpose |
|------|--------|-------------|---------|
| `TARPN_Home_Latest.zip` | Web | `~/tarpn-home/` (unzipped) | Web application files |
| `update_tarpn_home.sh` | Web | `/usr/local/sbin/update_tarpn_home.sh` | Update script |
| `home.service` | Web | `/etc/systemd/system/home.service` | Systemd service |
| `home_background.sh` | Web | `/usr/local/sbin/home_background.sh` | Service launcher |

**Neighbor Port Association**:
| File | Source | Destination | Purpose |
|------|--------|-------------|---------|
| `neighbor_port_association.zip` | Web | `/usr/local/sbin/neighbor_port_association` | Port mapping app |
| `neighbor_port_association.service` | Web | `/etc/systemd/system/neighbor_port_association.service` | Systemd service |
| `neighbor_port_association.sh` | Web | `/usr/local/sbin/neighbor_port_association.sh` | Service launcher |

**TRR Link Quality Program**:
| File | Source | Destination | Purpose |
|------|--------|-------------|---------|
| `trr.sh` | Web | `/usr/local/sbin/trr.sh` | TRR launcher script |
| `trr` | Web | `/usr/local/sbin/trr` | W4EIP link quality app |
| `w4eip_link_quality.txt` | Web | `~/w4eip_link_quality.txt` | Documentation |

**Audio Files**:
| File | Source | Destination | Purpose |
|------|--------|-------------|---------|
| `ringnoises.zip` | Web | `~/ringfolder/` (unzipped) | Audio notification files |

---

### 3. `tarpn_start2.sh`
**Location**: `/usr/local/sbin/tarpn_start2.sh` (moved here by tarpn_start1dl.sh)  
**Version**: BULLSEYE 029

#### What It Does:
- **System Updates**
  - Runs `apt-get update` and `apt-get dist-upgrade` again

- **Service Installation**
  - Installs `tarpn.service` → `/etc/systemd/system/tarpn.service`
  - Installs `pi_shutdown.service` → `/etc/systemd/system/pi_shutdown.service`
  - Installs `statusmonitor.service` → `/etc/systemd/system/statusmonitor.service`
  - Installs `rx_tarpnstat.service` → `/etc/systemd/system/rx_tarpnstat.service`

- **Application Installation**
  - Listen application (for monitoring packets)
  - Linktest application (for testing links)
  - BBS checker application
  - SendRoutesToCQ application
  - RX TarpnStat application
  - G8BPQ link stress test tool
  - NinoTNC version reader (getver.py)

- **Desktop Configuration**
  - Installs Midori web browser
  - Sets desktop wallpaper (`ncpacket-wallpaper.gif`)
  - Creates test files in `~/bpq/Files/`

#### What It Calls:
- No other scripts (final installation step)

#### What Gets Installed:

**Systemd Services**:
| Service | Source File | Destination | Background Script | Purpose |
|---------|-------------|-------------|-------------------|---------|
| `tarpn.service` | `tarpn-service.txt` | `/etc/systemd/system/tarpn.service` | `/usr/local/sbin/tarpn_background.sh` | Main TARPN service |
| `pi_shutdown.service` | `pi_shutdown-service.txt` | `/etc/systemd/system/pi_shutdown.service` | `/usr/local/sbin/pi_shutdown_background.sh` | Shutdown handler |
| `statusmonitor.service` | `statusmonitor-service.txt` | `/etc/systemd/system/statusmonitor.service` | `/usr/local/sbin/statusmonitor.sh` | System monitoring |
| `rx_tarpnstat.service` | `rx_tarpnstat-service.txt` | `/etc/systemd/system/rx_tarpnstat.service` | `/usr/local/sbin/rx_tarpnstat.sh` | Stats receiver |

**Applications** (all installed to `/usr/local/sbin/`):
| Application | Source | Purpose |
|-------------|--------|---------|
| `listen` | `listen.zip` | Packet monitoring tool |
| `linktest` | `linktest.zip` | Link testing tool |
| `bbs_checker` | `bbs_checker.zip` | BBS availability checker |
| `sendroutestocq` | `sendroutestocq.zip` | Route propagation tool |
| `rx_tarpnstatapp` | `rx_tarpnstatapp.zip` | Statistics receiver |
| `logfiletruncate.sh` | Web | Log file management |
| `g8bpq_link_stress.py` | `g8bpq_link_stress.zip` | Link stress testing |
| `getver.py` | Web | NinoTNC version reader |
| `ring.wav` | Web | Audio notification file |

**Desktop Files**:
| File | Source | Destination | Purpose |
|------|--------|-------------|---------|
| `ncpacket-wallpaper.gif` | Web | `/usr/share/rpd-wallpaper/ncpacket-wallpaper.gif` | Desktop wallpaper |

**Configuration Files**:
| File | Destination | Purpose |
|------|-------------|---------|
| `background.ini` | `/usr/local/etc/background.ini` | Background execution config (set to OFF) |
| `g8bpqloop.txt` | `~/bpq/Files/g8bpqloop.txt` | 10K test file for BBS |

**Flag Files**:
| File | Purpose |
|------|---------|
| `/usr/local/etc/tarpn_start2_top.txt` | Prevents re-running tarpn_start2.sh |
| `/usr/local/sbin/tarpn_start2.flag` | Indicates successful completion |

---

### 4. `tarpn` (Runtime Management Script)
**Location**: `/usr/local/sbin/tarpn`  
**Version**: vbullseye165

#### What It Does:
This is the main command-line interface for managing TARPN after installation. It does NOT install anything but provides commands for:

- **System Management**
  - `tarpn service start/stop` - Control TARPN service
  - `tarpn home start/stop` - Control TARPN Home web interface
  - `tarpn reboot/shutdown` - System power management

- **Configuration**
  - `tarpn test` - Test node configuration
  - `tarpn update` - Update TARPN software
  - `tarpn backup/restore` - Backup/restore configuration

- **Diagnostics**
  - `tarpn sysinfo` - Display system information
  - `tarpn usb` - List USB/serial devices
  - `tarpn ports` - Show network ports
  - `tarpn daemon` - View service logs

- **TNC Management**
  - `tarpn flash <device> <firmware>` - Flash NinoTNC firmware
  - `tarpn identify <device>` - Identify TNC device

#### What It Calls:
- `/usr/local/sbin/runbpq.sh` - When testing node
- `/usr/local/sbin/get_tnc_version.py` - For TNC version detection
- `/usr/local/sbin/update_tarpn_home.sh` - When updating TARPN Home
- Various systemctl commands for service management

#### Files It References:
| File | Purpose |
|------|---------|
| `/usr/local/sbin/source_url.txt` | Download source URL |
| `~/node.ini` | Node configuration |
| `/usr/local/etc/background.ini` | Background service config |
| `/usr/local/etc/hardware.txt` | Hardware identification |
| Various log files in `/var/log/` | System logs |

---

## Installation Flow Diagram

```
Internet (https://tarpn.net/bullseye2021)
    │
    ├──> Downloads to the user's home / temp folders (rewritten for the real user by tarpn_portable.sh)
    │       - tarpnget.sh
    │       - sleep_with_count.sh
    │       - Various zip files
    │
    ├──> Installs to /usr/local/sbin/
    │       - tarpn (main CLI)
    │       - runbpq.sh
    │       - tarpn_background.sh
    │       - Various compiled apps
    │       - Python scripts
    │
    ├──> Installs to /etc/systemd/system/
    │       - tarpn.service
    │       - home.service
    │       - pi_shutdown.service
    │       - statusmonitor.service
    │       - rx_tarpnstat.service
    │       - neighbor_port_association.service
    │
    ├──> Installs to ~/bpq/
    │       - linbpq (main executable)
    │       - HTML/ (web interface)
    │       - Configuration files
    │       - Files/ (BBS files)
    │
    ├──> Installs to ~/tarpn-home/
    │       - Web application files
    │       - Python modules
    │
    ├──> Creates in /var/log/
    │       - Multiple log files
    │
    └──> Creates in /usr/local/etc/
            - Configuration flags
            - Hardware info
```

---

## Download Sources

All files are downloaded from: **`https://tarpn.net/bullseye2021/`**

### Helper Scripts (downloaded first):
- `tarpnget.sh` - Robust file downloader with retry logic
- `sleep_with_count.sh` - Countdown sleep utility
- `test_internet.sh` - Internet connectivity tester

### Core TARPN Files:
- `tarpn` - Main CLI script
- `runbpq.sh` - BPQ node launcher
- `tarpn_background.sh` - Background service
- `tarpn-service.txt` - Systemd service file

### BPQ Node Files:
- `bpq_6_0_21_40_mar_2021.zip` - LinBPQ executable and HTML files
- `boilerplate.cfg` - Configuration template
- `chatconfig.cfg` - Chat configuration
- `configure_node_ini.sh` - Node configurator
- `make_local_bpq.sh` - Build script

### TARPN Home Files:
- `TARPN_Home_Latest.zip` - Complete web application
- `home-service.txt` - Systemd service
- `home_background.sh` - Service launcher
- `update_tarpn_home.sh` - Update script

### Services and Applications:
- `pi_shutdown-service.txt` + `pi_shutdown_background.sh`
- `statusmonitor-service.txt` + `statusmonitor.sh`
- `rx_tarpnstat-service.txt` + `rx_tarpnstat.sh`
- `neighbor_port_association.zip` + service files
- `listen.zip`, `linktest.zip`
- `bbs_checker.zip`, `sendroutestocq.zip`
- `rx_tarpnstatapp.zip`
- `logfiletruncate.sh`

### Terminal Programs:
- `piminicom.zip` - Modified minicom
- `minicom.scr` - Minicom script
- `piqttermtcp.dms` - Qt terminal
- `QtTermTCP.ini` - Terminal config

### Additional Files:
- `ringnoises.zip` - Audio notifications
- `ring.wav` - BBS checker sound
- `trr.sh` + `w4eip_link_quality.txt` - TRR program
- `g8bpq_link_stress.zip` - Stress testing
- `g8bpqloop.txt` - Test file
- `ncpacket-wallpaper.gif` - Desktop image
- `getver.py` - NinoTNC version reader

---

## Summary of Installation Locations

### `/usr/local/sbin/` (System executables - main installation location)
All TARPN scripts, applications, and compiled binaries

### `/etc/systemd/system/` (System services)
All systemd service files for automatic startup

### `~/bpq/` (BPQ Node)
- Main executable: `linbpq`
- Web interface: `HTML/`
- Configuration files
- BBS files: `Files/`

### `~/tarpn-home/` (TARPN Home Web App)
Complete Python web application

### `/var/log/` (Log files)
All TARPN-related log files

### `/usr/local/etc/` (Configuration and flags)
- `background.ini` - Background execution config
- `hardware.txt` - Hardware detection results
- Various flag files for installation tracking

### `~/Desktop/` (User desktop)
- `qt-term` - Terminal program
- `QtTermTCP.ini` - Configuration

### `~/minicom/` (Minicom terminal)
Modified minicom installation

### `~/ringfolder/` (Audio files)
Ring tone notifications

---

## Script Dependencies

### tarpn_start1.sh requires:
- Running from the repo folder, as a normal (non-root) user with sudo
- Internet connection to `https://tarpn.net/bullseye2021/`
- Sudo access
- Debian-based Linux distribution

### tarpn_start1dl.sh requires:
- `/usr/local/sbin/source_url.txt` (created by tarpn_start1.sh)
- `/usr/local/sbin/tarpnget.sh` (downloaded by tarpn_start1.sh)
- `/usr/local/sbin/sleep_with_count.sh` (downloaded by tarpn_start1.sh)
- Internet connection
- `tarpn_start2.sh` and `tarpn` present in the repo folder (they are copied, not moved)

### tarpn_start2.sh requires:
- `/usr/local/sbin/tarpn_start1_finished.flag` (created by tarpn_start1dl.sh)
- `/usr/local/sbin/source_url.txt`
- `/usr/local/sbin/tarpnget.sh`
- `/usr/local/sbin/sleep_with_count.sh`
- Internet connection

### tarpn (runtime) requires:
- `/usr/local/sbin/source_url.txt`
- `~/node.ini` (for most commands)
- `/usr/local/sbin/runbpq.sh`
- Various service files and log files created during installation

---

## Post-Installation System State

After all three scripts complete:

1. **Services Running:**
   - `tarpn.service` - Main TARPN background operations
   - `home.service` - TARPN Home web interface
   - `pi_shutdown.service` - Shutdown management
   - `statusmonitor.service` - System monitoring
   - `rx_tarpnstat.service` - Statistics receiver
   - `neighbor_port_association.service` - Port mapping

2. **Available Commands:**
   - `tarpn` - Main management CLI (available system-wide)

3. **Web Interfaces:**
   - BPQ Node web interface (after configuration)
   - TARPN Home web interface (port 8080)

4. **Ready for Configuration:**
   - Node configuration via `~/bpq/configure_node_ini.sh`
   - TNC configuration via `tarpn` command
   - Web configuration via TARPN Home

---

## Version Information

- **tarpn_start1.sh**: BULLSEYE 022
- **tarpn_start1dl.sh**: BULLSEYE 021
- **tarpn_start2.sh**: BULLSEYE 029
- **tarpn**: vbullseye165
- **OS Target**: Debian 11 (Bullseye)
- **BPQ Version**: 6.0.21.40 (March 2021)
- **Source URL**: https://tarpn.net/bullseye2021

---

## Notes

1. All scripts are designed for Debian 11 (Bullseye) but will work on most Debian-based systems
2. Platform-specific checks can be bypassed with `/usr/local/etc/bypass-platform-checks.txt`
3. Each script creates flag files to prevent re-running and track installation progress
4. The installation requires two system reboots (after tarpn_start1dl.sh and tarpn_start2.sh)
5. All downloads use retry logic (3 attempts) for reliability
6. Log files are created early and used throughout installation for debugging


---

## Portability layer (Tarpn-Anything additions)

- **`tarpn_portable.sh`** is sourced by all three installers and by `tarpnget.sh`. It records the user, detects the CPU (`arm32`, `arm64`, `x86_64`, `x86`), prepares armhf/QEMU/i386 support, ensures `python3.9` for TARPN HOME, and rewrites downloaded scripts.
- **start1dl by CPU:** x86 PCs get G8BPQ's Intel `linbpq` and `QtTermTCP`/`QtTermTCP64`; ARM gets the Pi builds from tarpn.net. `piminicom` falls back to stock `minicom` if the ARM build will not start.
- **start2 additions:** `gpio_for_controlpanel.sh` and the pi_shutdown service only on a Raspberry Pi; tarpn-mon service, `trr.app` and `l4listen` installed (the original installers only got them via `tarpn update`).
- **`tarpn update`** is disabled; **`tarpn updateapps`** works only on 32-bit ARM.
- **Untested:** none of this has been run end to end on a fresh Pi, ARM64 or x86 machine yet.
