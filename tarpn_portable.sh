#!/bin/bash
#### tarpn_portable.sh  --  Tarpn-Anything portability layer
####
#### This file is SOURCED (not run) by tarpn_start1.sh, tarpn_start1dl.sh, tarpn_start2.sh
#### and (after installation) by /usr/local/sbin/tarpnget.sh.  It is installed to
#### /usr/local/sbin/tarpn_portable.sh by tarpn_start1.sh.
####
#### What it does:
####   1. Remembers WHICH USER the node is installed for and WHERE that user's home is
####      (/usr/local/etc/tarpn_user.conf).  The original TARPN scripts assume the user is "pi"
####      and the home is /home/pi.  Many of them run as root from systemd, where $HOME and
####      $USER are useless, so the real user/home is written into them as literal text.
####   2. Detects the CPU type (32-bit ARM, 64-bit ARM, x86_64, x86) and prepares the system
####      so the ARM-built TARPN programs can run there too.
####   3. Re-writes every script that is downloaded from the TARPN web site so that it uses the
####      installing user instead of "pi" (see tarpn_patch_file).

TARPN_CONF_FILE="/usr/local/etc/tarpn_user.conf"

# The original scripts set TARPNCOMMANDLOGFILE but write to TARPN_COMMAND_LOGFILE in places
# ("ambiguous redirect").  Give the second spelling the same log file.
: "${TARPN_COMMAND_LOGFILE:=/var/log/tarpn_command.log}"
export TARPN_COMMAND_LOGFILE

# Print tarpn-mon's own version (e.g. v0.1.1).  The original check took the Go compiler's
# version (e.g. 1.22.5) from -debug-info instead, which never matches tarpn-mon-version.txt.
# Current builds stamp the app version in as:   build  -ldflags="-X main.Version=v0.1.1"
tarpn_mon_version() {
   local info ver
   info="$(tarpn-mon -debug-info 2>/dev/null)"
   ver="$(printf '%s\n' "$info" | sed -n 's/.*main\.Version=\([^" ]*\).*/\1/p' | head -1)"
   # older builds without the stamp: fall back to the original method
   [ -z "$ver" ] && ver="$(printf '%s\n' "$info" | grep go | grep -v github | cut -do -f3)"
   printf '%s\n' "$ver"
}

#### ---- user / home --------------------------------------------------------------------------

# Work out which (non-root) user the node belongs to and remember it.
tarpn_record_user() {
   local u="${SUDO_USER:-$USER}"
   if [ -z "$u" ] || [ "$u" = "root" ]; then
      return 1          # the caller prints the explanation (tarpn_fail_fix)
   fi
   local h
   h=$(getent passwd "$u" | cut -d: -f6)
   [ -z "$h" ] && h="/home/$u"
   TARPN_USER="$u"
   TARPN_HOME="$h"
   TARPN_USER_GROUP=$(id -gn "$u")
   {
      echo "TARPN_USER=\"$TARPN_USER\""
      echo "TARPN_HOME=\"$TARPN_HOME\""
      echo "TARPN_USER_GROUP=\"$TARPN_USER_GROUP\""
      # where the Tarpn-Anything repo is, so error messages after the reboot can say where to go
      [ -n "$TARPN_SRC_DIR" ] && echo "TARPN_SRC_DIR=\"$TARPN_SRC_DIR\""
   } > /tmp/tarpn_user.conf.$$
   sudo mkdir -p /usr/local/etc
   sudo mv /tmp/tarpn_user.conf.$$ "$TARPN_CONF_FILE"
   sudo chown root "$TARPN_CONF_FILE"
   sudo chmod 644 "$TARPN_CONF_FILE"
   return 0
}

# Load the remembered user/home (works for root/systemd too).
tarpn_load_user() {
   if [ -f "$TARPN_CONF_FILE" ]; then
      . "$TARPN_CONF_FILE"
   fi
   if [ -z "$TARPN_USER" ]; then
      TARPN_USER="${SUDO_USER:-$USER}"
      TARPN_HOME=$(getent passwd "$TARPN_USER" | cut -d: -f6)
   fi
}

tarpn_load_user

#### ---- CPU architecture ---------------------------------------------------------------------

# Sets TARPN_ARCH to one of: arm32  arm64  x86_64  x86  unknown
tarpn_detect_arch() {
   case "$(uname -m)" in
      armv6l|armv7l|armv8l|arm)  TARPN_ARCH="arm32" ;;
      aarch64|arm64)             TARPN_ARCH="arm64" ;;
      x86_64|amd64)              TARPN_ARCH="x86_64" ;;
      i?86)                      TARPN_ARCH="x86" ;;
      *)                         TARPN_ARCH="unknown" ;;
   esac
   export TARPN_ARCH
}
tarpn_detect_arch

# Does this machine run 32-bit ARM (armhf) programs natively?
tarpn_can_run_armhf_natively() {
   [ "$TARPN_ARCH" = "arm32" ] && return 0
   [ "$TARPN_ARCH" != "arm64" ] && return 1
   [ -e /lib/ld-linux-armhf.so.3 ] || [ -e /usr/lib/arm-linux-gnueabihf/ld-linux-armhf.so.3 ] || return 1
   # the CPU itself must support 32-bit mode (Pi 3/4/5 do; some other ARM64 chips do not)
   grep -qiE 'CPU architecture:\s*(7|8)' /proc/cpuinfo 2>/dev/null || return 1
   return 0
}

# Run a 32-bit ARM program and see if it works here.  $1 = program, rest = args.
tarpn_armhf_works() {
   "$@" >/dev/null 2>&1
   return $?
}

# Install whatever is needed so that 32-bit ARM TARPN programs can run on this machine.
# Safe to call more than once.
tarpn_prepare_arch() {
   echo "##### Preparing this ${TARPN_ARCH} system to run the TARPN programs"
   case "$TARPN_ARCH" in
      arm32)
         echo "  32-bit ARM: native. Nothing extra needed."
         ;;
      arm64)
         echo "  64-bit ARM: adding 32-bit ARM (armhf) support libraries"
         sudo dpkg --add-architecture armhf 2>/dev/null
         sudo apt-get -y update
         sudo apt-get -y install libc6:armhf libstdc++6:armhf libgcc-s1:armhf 2>/dev/null \
            || sudo apt-get -y install libc6:armhf libstdc++6:armhf
         # piminicom wants the old libtinfo.so.5; newer distros only ship .so.6
         sudo apt-get -y install libtinfo5:armhf 2>/dev/null || tarpn_fake_tinfo5 /usr/lib/arm-linux-gnueabihf
         # Fallback for 64-bit ARM chips that cannot run 32-bit code at all: emulate.
         if ! tarpn_can_run_armhf_natively; then
            echo "  This CPU cannot run 32-bit ARM code natively - installing QEMU emulation"
            tarpn_install_qemu || return 1
         fi
         ;;
      x86_64|x86)
         echo "  PC (x86): the 32-bit ARM helper programs will be run through QEMU emulation"
         tarpn_install_qemu || return 1
         if [ "$TARPN_ARCH" = "x86_64" ]; then
            # LinBPQ for PCs is a 32-bit Intel program.  Its libraries (from ldd):
            # libc/libm/libpthread/librt (libc6:i386), libgcc_s (libgcc-s1:i386), libz (zlib1g:i386)
            sudo dpkg --add-architecture i386 2>/dev/null
            sudo apt-get -y update
            sudo apt-get -y install libc6:i386 libgcc-s1:i386 zlib1g:i386 \
               || echo "  WARNING: could not install 32-bit Intel libraries (libc6:i386 libgcc-s1:i386 zlib1g:i386)"
         fi
         ;;
      *)
         echo "  WARNING: unrecognised CPU type '$(uname -m)'.  Continuing, but the TARPN"
         echo "           programs are built for ARM and may not run."
         ;;
   esac
}

tarpn_install_qemu() {
   sudo apt-get -y install qemu-user-static binfmt-support libc6-armhf-cross 2>/dev/null \
      || sudo apt-get -y install qemu-user-static libc6-armhf-cross \
      || echo "  WARNING: could not install QEMU user emulation (qemu-user-static libc6-armhf-cross)"
   # Debian/Ubuntu look for the ARM libraries here when emulating
   if [ -d /usr/arm-linux-gnueabihf ] && [ ! -e /etc/qemu-binfmt/arm ]; then
      sudo mkdir -p /etc/qemu-binfmt
      sudo ln -s /usr/arm-linux-gnueabihf /etc/qemu-binfmt/arm
   fi
   # Switch ARM emulation on.  Distros do this two different ways, so do BOTH:
   #  - binfmt-support (Ubuntu 22.04, Debian 11/12): update-binfmts reads /usr/share/binfmts/qemu-arm
   #  - systemd-binfmt (newer distros):              reads /usr/lib/binfmt.d/*.conf
   # ORDER MATTERS: restarting systemd-binfmt wipes every registration in the kernel and
   # reloads only its own binfmt.d list - on Ubuntu 22.04 that list has no qemu.  So restart
   # it FIRST, and do update-binfmts LAST so nothing can undo it afterwards.
   sudo systemctl restart systemd-binfmt 2>/dev/null
   if command -v update-binfmts >/dev/null 2>&1 && [ -f /usr/share/binfmts/qemu-arm ]; then
      sudo update-binfmts --import qemu-arm
      sudo update-binfmts --enable qemu-arm
   fi
   # libtinfo.so.5 for piminicom (only if we end up using it)
   [ -d /usr/arm-linux-gnueabihf/lib ] && tarpn_fake_tinfo5 /usr/arm-linux-gnueabihf/lib
   # Make sure it really worked - every ARM TARPN program depends on it
   if grep -qs '^enabled' /proc/sys/fs/binfmt_misc/qemu-arm; then
      echo "  QEMU ARM emulation is on."
   else
      return 1          # the caller prints the explanation (tarpn_fail_fix)
   fi
}

# Make libtinfo.so.5 point at libtinfo.so.6 in directory $1, if .5 is missing.
tarpn_fake_tinfo5() {
   local d="$1"
   [ -e "$d/libtinfo.so.5" ] && return 0
   if [ -e "$d/libtinfo.so.6" ]; then
      sudo ln -s libtinfo.so.6 "$d/libtinfo.so.5"
   fi
}

#### ---- Python 3.9 for TARPN HOME -------------------------------------------------------------

TARPN_PYTHON_FILE="/usr/local/etc/tarpn_python.txt"

# The TARPN HOME web dashboard is shipped only as Python 3.9 bytecode (tarpn_home.pyc).
# Bytecode from 3.9 will NOT load on any other Python version.  Find or install python3.9 and
# remember which interpreter to use (read back by tarpn_patch_file).
tarpn_ensure_python39() {
   local py=""
   if python3 -c 'import sys; sys.exit(0 if sys.version_info[:2]==(3,9) else 1)' 2>/dev/null; then
      py="python3"
   else
      echo "##### Default python3 is not 3.9 - TARPN HOME needs 3.9.  Looking for python3.9..."
      command -v python3.9 >/dev/null 2>&1 || sudo apt-get install -y python3.9 python3.9-venv 2>/dev/null
      command -v python3.9 >/dev/null 2>&1 && py="python3.9"
   fi
   if [ -z "$py" ]; then
      echo "##### WARNING: Python 3.9 is not available on this system's package sources."
      echo "#####          The TARPN node itself will work, but the TARPN HOME web dashboard will not start."
      echo "#####          Install Python 3.9 (e.g. via deadsnakes PPA on Ubuntu, or pyenv), then run:"
      echo "#####            echo python3.9 | sudo tee $TARPN_PYTHON_FILE   and   tarpn home update"
      return 1
   fi
   if [ "$py" != "python3" ]; then
      # the modules must be installed for THAT interpreter
      $py -m pip --version >/dev/null 2>&1 || sudo $py -m ensurepip 2>/dev/null
      sudo $py -m pip install tornado pyserial telnetlib3 2>/dev/null \
         || sudo $py -m pip install --break-system-packages tornado pyserial telnetlib3 2>/dev/null \
         || echo "##### WARNING: could not install tornado/pyserial/telnetlib3 for $py"
   fi
   echo "$py" > /tmp/tarpn_python.txt.$$
   sudo mv /tmp/tarpn_python.txt.$$ "$TARPN_PYTHON_FILE"
   echo "##### TARPN HOME will use: $py"
   return 0
}

#### ---- error messages for the installers ---------------------------------------------------
####
#### Every place where an installer has to stop calls one of these.  Each prints a box saying what
#### went wrong, then EITHER how to fix it yourself and start again (tarpn_fail_fix), OR how to
#### report it on GitHub (tarpn_fail_report), and then stops the installer (exit 1).
####   tarpn_fail_fix      CODE "what went wrong" "how to fix, line 1" ["line 2" ...]
####   tarpn_fail_report   CODE "what went wrong"
####   tarpn_fail_download CODE FILE [URL]   - works out whether it is the internet, a short
####                                           hiccup, or a file missing from the server
####   tarpn_fail_unzip    CODE FILE         - disk full (fix) or a broken file (report)
####   tarpn_fail_leftover CODE "what was found" - left behind by an earlier install attempt
#### The installers set TARPN_INSTALL_PART=1 (tarpn_start1 / tarpn_start1dl) or 2 (tarpn_start2),
#### which decides what "start the install again" means.

TARPN_ISSUES_URL="https://github.com/Dkane00/Tarpn-Anything/issues"

_tarpn_box_line() { echo "####################################################################################"; }

_tarpn_say() {                          # print each argument (and each line in it) inside the box
   local a l
   for a in "$@"; do
      while IFS= read -r l; do echo "####  $l"; done <<< "$a"
   done
}

_tarpn_repo_dir() { echo "${TARPN_SRC_DIR:-<the folder you downloaded (git cloned) Tarpn-Anything into>}"; }

_tarpn_script_name() { basename "${TARPN_INSTALL_SCRIPT:-$0}"; }

_tarpn_stop_banner() {                  # $1 = error code   $2 = what went wrong
   echo; echo; echo
   _tarpn_box_line
   _tarpn_say "THE TARPN INSTALL HAS STOPPED     error $1   in $(_tarpn_script_name)"
   _tarpn_box_line
   _tarpn_say "What went wrong:" "$(echo "$2" | sed 's/^/   /')"
   # keep a record in the TARPN command log too
   echo "$(date) Tarpn-Anything install stopped: $1 in $(_tarpn_script_name): $(echo "$2" | head -1)" \
      | sudo -n tee -a /var/log/tarpn_command.log >/dev/null 2>&1
}

# Things an install attempt leaves behind that make the NEXT attempt stop ("already ran",
# "already existed", "spoiled file-system").  Part 1 = tarpn_start1 + tarpn_start1dl.
_TARPN_PART1_FILES="/usr/local/etc/sudoerstest.txt /usr/local/sbin/tarpn_start1dl.flag /usr/local/sbin/tarpn_start1dl_starttime.txt /usr/local/sbin/tarpn_start1_finished.flag"
_TARPN_PART1_HOMEFILES="home.service neighbor_port_association-service.txt"
_TARPN_PART1_SERVICES="home.service neighbor_port_association.service tarpn_mon.service"
_TARPN_PART2_FILES="/usr/local/etc/tarpn_start2_top.txt /usr/local/sbin/tarpn_start2.flag /etc/systemd/system/pi_shutdown-service.txt"
_TARPN_PART2_HOMEFILES="tarpn.service pi_shutdown.service"
_TARPN_PART2_SERVICES="tarpn.service pi_shutdown.service statusmonitor.service rx_tarpnstat.service"

# Print how to start the install again.  Only lists clean-up commands for things that are
# really on this machine right now.
tarpn_how_to_retry() {
   local part="${TARPN_INSTALL_PART:-1}" repo cmds=() f s home="${TARPN_HOME:-$HOME}"
   repo="$(_tarpn_repo_dir)"
   if [ "$part" = "done" ]; then
      _tarpn_say "TO INSTALL AGAIN FROM SCRATCH" \
         "  Start over on a freshly installed system (or a virtual machine snapshot taken before" \
         "  the install), then run:   cd $repo   and   ./tarpn_start1.sh"
      return 0
   fi
   local files="$_TARPN_PART1_FILES" homefiles="$_TARPN_PART1_HOMEFILES" services="$_TARPN_PART1_SERVICES" script="tarpn_start1.sh"
   if [ "$part" = "2" ]; then
      files="$_TARPN_PART2_FILES"; homefiles="$_TARPN_PART2_HOMEFILES"; services="$_TARPN_PART2_SERVICES"; script="tarpn_start2.sh"
   fi
   for s in $services; do
      [ -f "/etc/systemd/system/$s" ] && cmds+=("sudo systemctl disable --now $s" "sudo rm -f /etc/systemd/system/$s")
   done
   [ ${#cmds[@]} -gt 0 ] && cmds+=("sudo systemctl daemon-reload")
   for f in $files; do [ -e "$f" ] && cmds+=("sudo rm -f $f"); done
   for f in $homefiles; do [ -e "$home/$f" ] && cmds+=("rm -f $home/$f"); done
   if [ "$part" = "1" ] && grep -qE '^trr[[:space:]]+63000/tcp' /etc/services 2>/dev/null; then
      cmds+=("sudo sed -i -E '/^(trr|linux|tchat|tinfo|linktest)[[:space:]]+6300[0-4]\/tcp/d' /etc/services")
   fi
   _tarpn_say "HOW TO START THE INSTALL AGAIN"
   _tarpn_say "  1. Fix the problem described above."
   if [ ${#cmds[@]} -gt 0 ]; then
      _tarpn_say "  2. This try already left some things behind that would stop the next try." \
                 "     Remove them with these commands (copy and paste them one line at a time):"
      for f in "${cmds[@]}"; do _tarpn_say "        $f"; done
      _tarpn_say "  3. Start again, as your normal user (NOT with sudo):"
   else
      _tarpn_say "  2. Start again, as your normal user (NOT with sudo):"
   fi
   _tarpn_say "        cd $repo" "        ./$script"
   if [ "$part" = "2" ]; then
      _tarpn_say "     (that runs only part 2 - part 1 finished fine)"
   fi
   _tarpn_say "  If it then stops with \"already ran\" or \"already existed\", the sure way is to start" \
              "  over on a freshly installed system (or go back to a virtual machine snapshot)" \
              "  and run ./tarpn_start1.sh there."
}

# Write a report file to paste into a GitHub issue.  $1 = code  $2 = what went wrong
_tarpn_write_report() {
   local repo_dir="${TARPN_SRC_DIR:-}"
   TARPN_REPORT_FILE="${TARPN_HOME:-$HOME}/tarpn-anything-error-report.txt"
   {
      echo "Tarpn-Anything install error report"
      echo "==================================="
      echo "Error:        $1"
      echo "Script:       $(_tarpn_script_name)   (install part ${TARPN_INSTALL_PART:-?}, line ${_TARPN_FAIL_LINE:-?})"
      echo "What failed:  $(echo "$2" | tr '\n' ' ')"
      echo "Date:         $(date)"
      if [ -n "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
         echo "Tarpn-Anything version: $(git -C "$repo_dir" log -1 --format='%h %cd %s' --date=short 2>/dev/null)  branch $(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
         echo "Local changes in the repo: $(git -C "$repo_dir" status --porcelain 2>/dev/null | wc -l) files"
      else
         echo "Tarpn-Anything version: unknown (repo folder: ${repo_dir:-not recorded})"
      fi
      echo
      echo "--- system"
      grep -E '^(PRETTY_NAME|VERSION_ID|ID|ID_LIKE)=' /etc/os-release 2>/dev/null
      echo "Kernel/CPU:   $(uname -srvm)"
      echo "TARPN CPU type: ${TARPN_ARCH:-?}"
      [ -r /proc/device-tree/model ] && echo "Board:        $(tr -d '\0' < /proc/device-tree/model)"
      command -v systemd-detect-virt >/dev/null 2>&1 && echo "Virtual machine: $(systemd-detect-virt 2>/dev/null)"
      echo "User:         ${TARPN_USER:-$USER}   home ${TARPN_HOME:-$HOME}   (running as $(whoami))"
      echo "Python:       $(python3 -V 2>&1)"
      echo "ARM emulation: $(head -1 /proc/sys/fs/binfmt_misc/qemu-arm 2>/dev/null || echo 'not set up')"
      echo "Free disk:    $(df -Ph "${TARPN_HOME:-$HOME}" 2>/dev/null | awk 'NR==2{print $4" free of "$2}')"
      echo "Memory:       $(free -h 2>/dev/null | awk '/^Mem:/{print $2" total, "$7" available"}')"
      echo "tarpn.net reachable: $(wget -q --spider --timeout=15 --tries=1 https://tarpn.net/ 2>/dev/null && echo yes || echo NO)"
      echo
      echo "--- install markers present"
      for f in $_TARPN_PART1_FILES $_TARPN_PART2_FILES; do [ -e "$f" ] && echo "  $f"; done
      for f in $_TARPN_PART1_SERVICES $_TARPN_PART2_SERVICES; do [ -e "/etc/systemd/system/$f" ] && echo "  /etc/systemd/system/$f"; done
      echo
      for f in /var/log/tarpn_command.log /var/log/tarpn_startstop.log /var/log/tarpn_home.log; do
         [ -r "$f" ] || continue
         echo "--- last 25 lines of $f"
         tail -n 25 "$f"
         echo
      done
   } > "$TARPN_REPORT_FILE" 2>&1
}

# Stop: something the user can fix.   CODE  "what went wrong"  "fix line" ...
tarpn_fail_fix() {
   : "${_TARPN_FAIL_LINE:=${BASH_LINENO[0]}}"
   local code="$1" what="$2"; shift 2
   _tarpn_stop_banner "$code" "$what"
   if [ $# -gt 0 ]; then
      _tarpn_say "" "How to fix it:"
      local l; for l in "$@"; do _tarpn_say "   $l"; done
   fi
   _tarpn_box_line
   tarpn_how_to_retry
   _tarpn_box_line
   exit 1
}

# Stop: something the user can't sensibly fix - ask for a GitHub issue.   CODE  "what went wrong"
tarpn_fail_report() {
   : "${_TARPN_FAIL_LINE:=${BASH_LINENO[0]}}"
   local code="$1" what="$2"
   _tarpn_stop_banner "$code" "$what"
   _tarpn_write_report "$code" "$what"
   _tarpn_say "" \
      "This is probably a bug in Tarpn-Anything, or something changed on the TARPN web" \
      "server - not something you should have to fix yourself.  Please report it:" \
      "" \
      "  1. Open   $TARPN_ISSUES_URL/new" \
      "     (you need a free GitHub account - sign in or sign up there)" \
      "  2. Title:   Install stopped with error $code in $(_tarpn_script_name)" \
      "  3. Paste in the text of the report file that was just written for you:" \
      "        $TARPN_REPORT_FILE" \
      "     To show it so you can copy it:   cat $TARPN_REPORT_FILE" \
      "  4. Also paste the last 40 or so lines the install printed above this box." \
      "  5. Say what you installed on (Raspberry Pi model, or PC / virtual machine), and" \
      "     whether it was a freshly installed system or the install had been run before." \
      "" \
      "The report holds your Linux version, CPU type, user name, free disk space and the" \
      "last lines of the TARPN logs - no passwords.  Look it over before posting if you like." \
      "" \
      "When a fix is available, get it with:   cd $(_tarpn_repo_dir)  &&  git pull" \
      "and then start again as described below."
   _tarpn_box_line
   tarpn_how_to_retry
   _tarpn_box_line
   exit 1
}

# Stop because a download failed.  CODE FILE [URL]   (URL defaults to the TARPN script server)
tarpn_fail_download() {
   : "${_TARPN_FAIL_LINE:=${BASH_LINENO[0]}}"
   local code="$1" file="$2" url="$3" base host probe
   if [ -z "$url" ]; then
      base="${_source_url:-$(tr -d '\0' </usr/local/sbin/source_url.txt 2>/dev/null)}"
      url="${base:-https://tarpn.net/bullseye2021}/$file"
   fi
   host=$(echo "$url" | sed -E 's#^[a-z]+://([^/]+).*#\1#')
   if ! wget -q --spider --timeout=20 --tries=2 "https://$host/" 2>/dev/null && \
      ! wget -q --spider --timeout=20 --tries=2 "http://$host/" 2>/dev/null; then
      tarpn_fail_fix "$code" "Could not download $file - this computer cannot reach $host." \
         "Check that this computer is on the internet, for example:   ping -c 3 $host" \
         "If it uses Wi-Fi or a VPN, make sure that is connected." \
         "If the internet works but $host does not answer, the site may be down - wait a while."
   fi
   probe=$(mktemp)
   wget -q -O "$probe" --timeout=60 --tries=2 "$url" 2>/dev/null
   if [ -s "$probe" ] && ! { [ "$(wc -c < "$probe")" -lt 3000 ] && grep -qi 'packet_radio_networking.html' "$probe"; }; then
      rm -f "$probe"
      tarpn_fail_fix "$code" "Could not download $file, but it downloads fine now - so it was probably
a short internet or web-server hiccup." \
         "Nothing to fix - just start the install again (below)." \
         "If the same download keeps failing, please report it at $TARPN_ISSUES_URL"
   fi
   rm -f "$probe"
   tarpn_fail_report "$code" "$host is working, but the file $file is not there any more:
   $url
The TARPN web server probably renamed or moved it, so the install scripts need an update."
}

# Stop because unpacking a downloaded zip failed.  CODE FILE
tarpn_fail_unzip() {
   : "${_TARPN_FAIL_LINE:=${BASH_LINENO[0]}}"
   local code="$1" file="$2" free_mb
   free_mb=$(df -Pm "${TARPN_HOME:-$HOME}" 2>/dev/null | awk 'NR==2{print $4}')
   if [ -n "$free_mb" ] && [ "$free_mb" -lt 500 ]; then
      tarpn_fail_fix "$code" "Could not unpack $file - the disk is almost full (${free_mb} MB free)." \
         "Free up some space (TARPN needs at least 1 GB free).  To see what uses space:" \
         "   df -h        and        du -sh ~/* | sort -h | tail" \
         "Then start the install again (below)."
   fi
   command -v unzip >/dev/null 2>&1 || tarpn_fail_fix "$code" "Could not unpack $file - the unzip program is missing." \
      "Install it:   sudo apt-get install -y unzip"
   tarpn_fail_report "$code" "Could not unpack $file (there is enough disk space).  The downloaded file is
probably damaged or in a format this unzip does not understand.  Trying the install once
more is worth it - if it fails the same way, please report it."
}

# Stop because an earlier install attempt left something behind.   CODE "what was found"
tarpn_fail_leftover() {
   : "${_TARPN_FAIL_LINE:=${BASH_LINENO[0]}}"
   tarpn_fail_fix "$1" "$2
This happens when the install is run again on a system where it already ran
(or stopped part-way).  The clean-up steps below remove what the earlier try left." \
      "Follow the clean-up steps below, then start again."
}

#### ---- rewriting downloaded scripts ---------------------------------------------------------

# Escape a string for use on the right-hand side of a sed s||| command.
_tarpn_sed_escape() {
   printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

# tarpn_patch_file FILE...
#   Rewrites a text file downloaded from the TARPN server so that
#     /home/pi        ->  the real home directory of the installing user
#     chown pi        ->  chown <user>          (also chown pi:pi)
#     sudo -u pi      ->  sudo -u <user>
#     whoami == "pi"  ->  whoami == "<user>"
#   Binary files and files that never mention "pi" are left alone.  Idempotent.
tarpn_patch_file() {
   local f
   [ -z "$TARPN_USER" ] && tarpn_load_user
   local H U G
   H=$(_tarpn_sed_escape "$TARPN_HOME")
   U=$(_tarpn_sed_escape "$TARPN_USER")
   G=$(_tarpn_sed_escape "${TARPN_USER_GROUP:-$TARPN_USER}")
   for f in "$@"; do
      [ -f "$f" ] || continue
      grep -Iq . "$f" 2>/dev/null || continue            # skip binary files
      sed -i \
         -e "s|/home/pi\b|$H|g" \
         -e "s|\bchown pi:pi\b|chown $U:$G|g" \
         -e "s|\bchown pi\b|chown $U|g" \
         -e "s|\bsudo -u pi\b|sudo -u $U|g" \
         -e "s|\(whoami[^\"]*\)\"pi\"|\1\"$U\"|g" \
         -e "s|\(USER[^\"]*\)\"pi\"|\1\"$U\"|g" \
         "$f"
      if [ -s "$TARPN_PYTHON_FILE" ]; then
         sed -i -e "s|\bpython3 tarpn_home\.pyc|$(cat $TARPN_PYTHON_FILE) tarpn_home.pyc|g" "$f"
      fi
      # runbpq.sh fetches boilerplate.cfg and make_local_bpq.sh by itself every time the node
      # starts - make sure those get the same treatment right after they are downloaded.
      if grep -q 'wget .*boilerplate\.cfg' "$f" 2>/dev/null && ! grep -q 'tarpn_patch_file' "$f"; then
         sed -i \
            -e '/wget .*boilerplate\.cfg/a . /usr/local/sbin/tarpn_portable.sh; tarpn_patch_file boilerplate.cfg' \
            -e '/wget .*make_local_bpq\.sh/a . /usr/local/sbin/tarpn_portable.sh; tarpn_patch_file make_local_bpq.sh' \
            "$f"
      fi
   done
}

#### ---- hook into tarpnget -------------------------------------------------------------------
#### tarpnget.sh (downloaded from the TARPN web site, installed in /usr/local/sbin) defines the
#### function tarpnget().  We wrap it: download as usual, then patch the file.
#### This only takes effect when this file is sourced AFTER tarpnget.sh, which is why
#### tarpn_start1.sh appends "source /usr/local/sbin/tarpn_portable.sh" to the end of tarpnget.sh.
if declare -F tarpnget >/dev/null 2>&1 && ! declare -F _tarpnget_original >/dev/null 2>&1; then
   eval "_tarpnget_original() $(declare -f tarpnget | tail -n +2)"
   tarpnget() {
      _tarpnget_original "$@"
      local rc=$?
      tarpn_patch_file "$1"
      return $rc
   }
fi
if declare -F tarpnget_path_and_filename >/dev/null 2>&1 && ! declare -F _tarpnget_paf_original >/dev/null 2>&1; then
   eval "_tarpnget_paf_original() $(declare -f tarpnget_path_and_filename | tail -n +2)"
   tarpnget_path_and_filename() {
      _tarpnget_paf_original "$@"
      local rc=$?
      tarpn_patch_file "$2"
      return $rc
   }
fi
