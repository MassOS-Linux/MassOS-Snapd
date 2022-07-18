#!/bin/bash

# Snapd installation script for MassOS, part of the MassOS-Snapd project.
# Copyright (C) 2022 MassOS Developers. Please see 'LICENSE' for copying terms.

# Exit on error.
set -e

# Ensure we are running as root.
if [ $EUID -ne 0 ]; then
  echo "Error: $(basename "$0") must be run as root." >&2
  exit 1
fi

# Ensure we are running on MassOS.
if [ ! -e /etc/massos-release ]; then
  echo "Error: $(basename "$0") must be run from MassOS."
  exit 1
fi
MASSOS_RELEASE="$(cat /etc/massos-release)"

# Check whether snapd is already installed.
if snap list &>/dev/null; then
  echo "Error: snapd is already installed." >&2
  echo >&2
  echo "Run 'sudo /usr/lib/snapd/update-snapd.sh' to update snapd." >&2
  echo "Run 'sudo /usr/lib/snapd/remove-snapd.sh' to remove snapd." >&2
  exit 1
fi

# Ensure the minimum MassOS version (2022.07) is met.
REL_YEAR="$(echo "$MASSOS_RELEASE" | cut -d. -f1)"
REL_MONTH="$(echo "$MASSOS_RELEASE" | cut -d. -f2)"
if [ "$MASSOS_RELEASE" = "development" ]; then
  # Don't exit on error for development builds, just warn the user.
  echo "Warning: If your development build is older than 2022.07, you will" >&2
  echo "experience issues." >&2
  echo >&2
elif [ $REL_YEAR -lt 2022 ]; then
  # Before 2022.
  echo "Error: Your MassOS version is too old (minimum 2022.07)." >&2
  exit 1
elif [ $REL_YEAR -eq 2022 ] && [ $REL_MONTH -lt 07 ]; then
  # In 2022 but before month 07.
  echo "Error: Your MassOS version is too old (minimum 2022.07)." >&2
  exit 1
fi

# Ensure arch is correct.
if [ "$(uname -m)" != "x86_64" ]; then
  echo "Error: Only x86_64 is currently supported." >&2
  exit 1
fi

# Check for latest version of snapd.
echo "Checking the latest version of snapd..."
SNAPD_VERSION="$(curl -s https://api.github.com/repos/MassOS-Linux/MassOS-Snapd/releases/latest | grep tag_name | cut -d'"' -f4)"

# Confirmation prompt.
read -p "Would you like to install snapd ${SNAPD_VERSION} now? [y/N] " ans
answer="$(echo "$ans" | cut -c1 | tr '[:upper:]' '[:lower:]')"
if [ "$answer" != "y" ]; then
  exit 1
fi


# Change to a working directory.
savedir="$PWD"
workdir="$(mktemp -d)"
cd "$workdir"

# Download the snapd binary.
echo "Downloading snapd ${SNAPD_VERSION}..."
curl -LO https://github.com/MassOS-Linux/MassOS-Snapd/releases/download/${SNAPD_VERSION}/snapd-${SNAPD_VERSION}-x86_64-MassOS.tar.xz

# Extract the tarball.
echo "Unpacking snapd ${SNAPD_VERSION}..."
mkdir pkg
tar --no-same-owner --same-permissions -xf snapd-${SNAPD_VERSION}-x86_64-MassOS.tar.xz -C pkg

# Install snapd.
echo "Installing snapd ${SNAPD_VERSION}..."
cp -a pkg/* /

# Set correct permissions of this directory.
chmod 111 /var/lib/snapd/void

# Post installation stuff.
update-desktop-database
systemctl daemon-reload
systemctl restart apparmor
systemctl enable --now snapd
systemctl enable --now snapd.apparmor

# Clean up.
echo "Cleaning up..."
cd "$savedir"
rm -rf "$workdir"

# Finishing message.
echo
echo "The installation of snapd ${SNAPD_VERSION} was successful. You must now"
echo "REBOOT the system before attempting to use it. After rebooting, run the"
echo "command 'snap help' for details on how to use the package manager."
echo
echo "If you want to check for new versions of snapd and install updates, run"
echo "the following command:"
echo
echo "  sudo /usr/lib/snapd/update-snapd.sh"
echo
echo "If you later decide you want to remove snapd from your system, firstly"
echo "remove all installed snap packages, then run the following command:"
echo
echo "  sudo /usr/lib/snapd/remove-snapd.sh"
echo
echo "We hope you enjoy using snapd on MassOS!"
echo
echo "snapd home page:        https://snapcraft.io"
echo "snapd source code repo: https://github.com/snapcore/snapd"
echo "MassOS-Snapd repo:      https://github.com/MassOS-Linux/MassOS-Snapd"
