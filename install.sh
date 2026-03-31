#!/usr/bin/env bash
set -e

# Pinned version — update this after verifying a new release via the sync workflow
PINNED_VERSION="v0.12.4"
BASE_URL="https://github.com/RemakingEden/cimon-releases/releases/download/${PINNED_VERSION}"
BINDIR="${BINDIR:-./bin}"

# Parse -b flag for custom install dir (matches upstream interface)
while getopts "b:dh" opt; do
    case $opt in
        b) BINDIR="$OPTARG" ;;
        d) set -x ;;
        h) echo "Usage: $0 [-b bindir]"; exit 0 ;;
    esac
done

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)          ARCH_LABEL="x86_64" ;;
    aarch64|arm64)   ARCH_LABEL="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

if [ "$OS" != "linux" ]; then
    echo "Unsupported OS: $OS (only linux is supported)"
    exit 1
fi

TARBALL="cimon_linux_${ARCH_LABEL}.tar.gz"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading cimon ${PINNED_VERSION} (${ARCH_LABEL})..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${BASE_URL}/${TARBALL}"      -o "${TMP}/${TARBALL}"
    curl -fsSL "${BASE_URL}/checksums.txt"   -o "${TMP}/checksums.txt"
elif command -v wget >/dev/null 2>&1; then
    wget -q "${BASE_URL}/${TARBALL}"      -O "${TMP}/${TARBALL}"
    wget -q "${BASE_URL}/checksums.txt"   -O "${TMP}/checksums.txt"
else
    echo "Neither curl nor wget found"; exit 1
fi

echo "Verifying checksum..."
cd "$TMP"
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum --check --ignore-missing checksums.txt
elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 --check --ignore-missing checksums.txt
else
    echo "No sha256 tool found — cannot verify integrity"; exit 1
fi

mkdir -p "$BINDIR"
tar -xzf "$TARBALL" -C "$BINDIR" --strip-components=1
chmod +x "$BINDIR/cimon"

echo "cimon ${PINNED_VERSION} installed to ${BINDIR}/cimon"
