#!/bin/bash

# Snapd build script for MassOS, part of the MassOS-Snapd project.
# Copyright (C) 2022 MassOS Developers. Please see 'LICENSE' for copying terms.

# Exit on error.
set -e

# Ensure we are running on MassOS.
if [ ! -e /etc/massos-release ]; then
  echo "Error: $(basename "$0") must be run from MassOS."
  exit 1
fi
MASSOS_RELEASE="$(cat /etc/massos-release)"

# Handle MassOS development builds.
if [ "$MASSOS_RELEASE" = "development" ]; then
  if [ -z "$1" ]; then
    echo "Error: Development build detected. Specify nearest version as an" >&2
    echo "argument. For example: $(basename "$0") 2022.07" >&2
    exit 1
  else
    MASSOS_RELEASE="$1"
  fi
fi

# Ensure the minimum MassOS version (2022.07) is met.
REL_YEAR="$(echo "${MASSOS_RELEASE}" | cut -d. -f1)"
REL_MONTH="$(echo "${MASSOS_RELEASE}" | cut -d. -f2)"
## Before 2022.
if [ $REL_YEAR -lt 2022 ]; then
  echo "Error: Your MassOS version is too old (minimum 2022.07)." >&2
  exit 1
fi
## Or in 2022 but before month 07.
if [ $REL_YEAR -eq 2022 ] && [ $REL_MONTH -lt 07 ]; then
  echo "Error: Your MassOS version is too old (minimum 2022.07)." >&2
  exit 1
fi


# Check and set the version.
SNAPD_VERSION="$(cat snapd-version)"

# Change to a temporary working directory.
savedir="$(pwd)"
wdir="$(mktemp -d)"
cd "$wdir"

# Download the stuff.
echo "Downloading snapd..."
curl -L https://github.com/snapcore/snapd/releases/download/${SNAPD_VERSION}/snapd_${SNAPD_VERSION}.vendor.tar.xz -o snapd.tar.xz
echo "Downloading golang..."
curl -L https://dl.google.com/go/go1.18.3.linux-amd64.tar.gz -o go.tar.gz

# Extract the stuff.
mkdir snapd go pkg
echo "Extracting snapd..."
tar -xf snapd.tar.xz -C snapd --strip-components=1
echo "Extracting golang..."
tar -xf go.tar.gz -C go --strip-components=1

# Setup environment variables.
export PATH="$wdir/go/bin:$PATH"
export GOPATH="$wdir/go"
export PKGDIR="$wdir/pkg"
export GO111MODULE=off
export CGO_ENABLED="1"
export MAKEFLAGS="-j$(nproc)"
unset CFLAGS CXXFLAGS LDFLAGS CGO_CFLAGS CGO_CXXFLAGS CGO_LDFLAGS

# Build snapd.
echo "Building snapd (may take a while)..."
mkdir -p go/src/github.com/snapcore
ln -fsT "$wdir/snapd" go/src/github.com/snapcore/snapd
cd snapd
./mkversion.sh ${SNAPD_VERSION} 2>/dev/null
go build -trimpath -ldflags "-s -w -linkmode external" -o ../go/bin/snap -tags nomanagers "github.com/snapcore/snapd/cmd/snap"
go build -trimpath -ldflags "-s -w -linkmode external" -o ../go/bin/snapd "github.com/snapcore/snapd/cmd/snapd"
go build -trimpath -ldflags "-s -w -linkmode external" -o ../go/bin/snapd-apparmor "github.com/snapcore/snapd/cmd/snapd-apparmor"
go build -trimpath -ldflags "-s -w -linkmode external" -o ../go/bin/snap-seccomp "github.com/snapcore/snapd/cmd/snap-seccomp"
go build -trimpath -ldflags "-s -w -linkmode external" -o ../go/bin/snap-failure "github.com/snapcore/snapd/cmd/snap-failure"
go build -trimpath -ldflags "-s -w -linkmode external -extldflags '-static'" -o ../go/bin/snap-update-ns "github.com/snapcore/snapd/cmd/snap-update-ns"
go build -trimpath -ldflags "-s -w -linkmode external -extldflags '-static'" -o ../go/bin/snap-exec "github.com/snapcore/snapd/cmd/snap-exec"
go build -trimpath -ldflags "-s -w -linkmode external -extldflags '-static'" -o ../go/bin/snapctl "github.com/snapcore/snapd/cmd/snapctl"
make -C data LIBEXECDIR=/usr/lib SYSTEMDSYSTEMUNITDIR=/usr/lib/systemd/system SNAPD_ENVIRONMENT_FILE=/etc/default/snapd
cd cmd
autoreconf -fi
./configure --prefix=/usr --libexecdir=/usr/lib/snapd --enable-apparmor --enable-merged-usr --enable-nvidia-biarch
make
cd ..

# Install snapd.
echo "Installing snapd..."
## Completions and data.
install -t "$PKGDIR"/usr/share/bash-completion/completions -Dm644 data/completion/bash/snap
install -t "$PKGDIR"/usr/lib/snapd -Dm644 data/completion/bash/{complete,etelpmoc}.sh
make -C data DBUSSERVICESDIR=/usr/share/dbus-1/services SYSTEMDSYSTEMUNITDIR=/usr/lib/systemd/system DESTDIR="$PKGDIR" install
install -t "$PKGDIR"/usr/share/polkit-1/actions -Dm644 data/polkit/io.snapcraft.snapd.policy
## Snap itself.
install -t "$PKGDIR"/usr/bin -Dm755 ../go/bin/snap
install -t "$PKGDIR"/usr/lib/snapd -Dm755 ../go/bin/snap{ctl,d{,-apparmor},-exec,-failure,-seccomp,-update-ns}
ln -sfr "$PKGDIR"/usr/lib/snapd/snapctl "$PKGDIR"/usr/bin/snapctl
install -dm755 "$PKGDIR"/snap
install -dm755 "$PKGDIR"/var/cache/snapd
install -dm755 "$PKGDIR"/var/lib/snapd/{apparmor,assertions,dbus-1/services,dbus-1/system-services,desktop/applications,device,hostfs,inhibit,lib/gl,lib/gl32,lib/vulkan,lib/glvnd,mount,seccomp/bpf,snaps}
install -dm700 "$PKGDIR"/var/lib/snapd/{cache,cookie}
make -C cmd DESTDIR="$PKGDIR" install
## Permissions should be 111 but this breaks tar, so chmod 755 here and reset when installed.
chmod -R 755 "$PKGDIR"/var/lib/snapd/void
## Man and info page.
install -dm755 "$PKGDIR"/usr/share/man/man8
"$PKGDIR"/usr/bin/snap help --man > "$PKGDIR"/usr/share/man/man8/snap.8
install -Dm644 ../go/src/github.com/snapcore/snapd/data/info "$PKGDIR"/usr/lib/snapd/info
for i in snap snap-confine snapd-env-generator snap-discard-ns; do
  gzip -9 "$PKGDIR"/usr/share/man/man8/"$i".8
done
## Remove Ubuntu-specific stuff.
rm -f "$PKGDIR"/usr/lib/systemd/system/snapd.{system-shutdown.service,autoimport.service,recovery-chooser-trigger.service,core-fixup.*,snap-repair.*}
rm -f "$PKGDIR"/usr/lib/snapd/{snapd.core-fixup.sh,system-shutdown}
rm -f "$PKGDIR"/usr/bin/ubuntu-core-launcher
# License file.
install -t "$PKGDIR"/usr/share/licenses/snapd -Dm644 COPYING

# Strip the binaries.
find "$PKGDIR" -type f -exec strip --strip-unneeded {} ';' &>/dev/null || true

# Install MassOS-Snapd management scripts.
install -t "$PKGDIR"/usr/lib/snapd -Dm755 "$savedir"/{remove,update}-snapd.sh

# Compress the stuff.
echo "Creating binary tarball..."
cd "$PKGDIR"
fakeroot tar --no-same-owner --same-permissions -cJf "$savedir/snapd-${SNAPD_VERSION}-x86_64-MassOS.tar.xz" *
cd "$savedir"

# Clean up.
echo "Cleaning up..."
rm -rf "$wdir"
echo "Successfully built snapd ${SNAPD_VERSION} for MassOS."
