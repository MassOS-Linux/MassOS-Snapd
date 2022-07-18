#!/bin/bash

# Snapd update script for MassOS, part of the MassOS-Snapd project.
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

# Ensure snap is actually installed.
if ! snap list &>/dev/null; then
  echo "Error: snapd doesn't appear to be installed." >&2
  exit 1
fi

# Check the installed version of snapd.
OLD_SNAPD_VERSION="$(snap version | xargs | cut -d' ' -f2)"

# Check the newer version of snapd.
echo "Checking the latest version of snapd..."
SNAPD_VERSION="$(curl -s https://api.github.com/repos/MassOS-Linux/MassOS-Snapd/releases/latest | grep tag_name | cut -d'"' -f4)"

if [ "$OLD_SNAPD_VERSION" = "$SNAPD_VERSION" ]; then
  echo "It looks like snapd is already up to date ($OLD_SNAPD_VERSION)."
  exit 0
fi

# Confirmation prompt.
read -p "Would you like to update to snapd ${SNAPD_VERSION} now? [y/N] " ans
answer="$(echo "$ans" | cut -c1 | tr '[:upper:]' '[:lower:]')"
if [ "$answer" != "y" ]; then
  exit 1
fi

# Stop existing snapd service.
systemctl -q stop snapd
systemctl -q stop snapd.apparmor

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

# Install updated snapd files.
echo "Upgrading snapd ${OLD_SNAPD_VERSION} to ${SNAPD_VERSION}..."
cd pkg
find . -type f -exec cp -a {} /{} ';'

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
echo "The upgrade of snapd from ${OLD_SNAPD_VERSION} to ${SNAPD_VERSION} was"
echo "successful. You must now REBOOT the system to complete the upgrade."
