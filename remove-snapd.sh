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

# Ensure snap is actually installed.
if ! snap list &>/dev/null; then
  echo "Error: snapd doesn't appear to be installed." >&2
  exit 1
fi

# Ensure no snap packages are installed.
if [ "$(snap list 2>&1 | cut -d. -f1)" != "No snaps are installed yet" ]; then
  echo "Error: You must uninstall all snap packages before removing snapd." >&2
  exit 1
fi

# Confirmation prompt.
read -p "Would you like to completely remove snapd now? [y/N] " ans
answer="$(echo "$ans" | cut -c1 | tr '[:upper:]' '[:lower:]')"
if [ "$answer" != "y" ]; then
  exit 1
fi

# Disable systemd services.
echo "Stopping and disabling snapd services..."
systemctl disable --now snapd
systemctl disable --now snapd.apparmor

# Remove all snapd components.
echo "Completely removing snapd..."
rm -f /etc/apparmor.d/usr.lib.snapd.snap-confine
rm -f /etc/profile.d/snapd.sh
rm -f /etc/xdg/autostart/snap-userd-autostart.desktop
rm -f /usr/bin/snap{,ctl}
rm -f /usr/lib/environment.d/990-snapd.conf
rm -rf /usr/lib/snapd
rm -f /usr/lib/systemd/system/snapd.*
rm -f /usr/lib/systemd/system-environment-generators/snapd-env-generator
rm -f /usr/lib/systemd/system-generators/snapd-generator
rm -f /usr/lib/systemd/user/snapd.session-agent.*
rm -f /usr/share/applications/{io.snapcraft.SessionAgent,snap-handle-link}.desktop
rm -f /usr/share/bash-completion/completions/snap
rm -f /usr/share/dbus-1/services/io.snapcraft.{Launcher,SessionAgent,Settings}.service
rm -f /usr/share/dbus-1/session.d/snapd.session-services.conf
rm -f /usr/share/dbus-1/system.d/snapd.system-services.conf
rm -f /usr/share/fish/vendor_conf.d/snapd.fish
rm -rf /usr/share/licenses/snapd
rm -f /usr/share/man/man8/snap{,-confine,-env-generator,-discard-ns}.8.gz
rm -f /usr/share/polkit-1/actions/io.snapcraft.snapd.policy
rm -rf /var/cache/snapd
rm -rf /var/lib/snapd
rm -rf /var/snap
rm -rf /snap

# Post removal stuff.
update-desktop-database
systemctl daemon-reload
systemctl restart apparmor

# Finishing message.
echo
echo "The complete removal of snapd was successful. You must now REBOOT the"
echo "system to ensure everything is fully cleaned up."
echo
echo "If you ever want to reinstall snapd, refer to the following URL:"
echo
echo "  https://github.com/MassOS-Linux/MassOS-Snapd"
echo
