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

#### ---- user / home --------------------------------------------------------------------------

# Work out which (non-root) user the node belongs to and remember it.
tarpn_record_user() {
   local u="${SUDO_USER:-$USER}"
   if [ -z "$u" ] || [ "$u" = "root" ]; then
      echo "ERROR:  Please run the installer as your normal (non-root) user, not as root."
      echo "ERROR:  That user needs sudo rights.  Example:  ./tarpn_start1.sh"
      return 1
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
            tarpn_install_qemu
         fi
         ;;
      x86_64|x86)
         echo "  PC (x86): the 32-bit ARM helper programs will be run through QEMU emulation"
         tarpn_install_qemu
         if [ "$TARPN_ARCH" = "x86_64" ]; then
            # LinBPQ for PCs is a 32-bit Intel program
            sudo dpkg --add-architecture i386 2>/dev/null
            sudo apt-get -y update
            sudo apt-get -y install libc6:i386 2>/dev/null \
               || echo "  WARNING: could not install 32-bit Intel libraries (libc6:i386)"
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
   sudo systemctl restart systemd-binfmt 2>/dev/null || sudo update-binfmts --enable qemu-arm 2>/dev/null
   # libtinfo.so.5 for piminicom (only if we end up using it)
   [ -d /usr/arm-linux-gnueabihf/lib ] && tarpn_fake_tinfo5 /usr/arm-linux-gnueabihf/lib
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
