#!/usr/bin/env bash
#
# AviumUI Magisk Boot Generator for OnePlus 6 (enchilada)
# Builds a rooted boot-magisk.img alongside stock boot.img without modifying stock.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$REPO_DIR/tools/magisk"

STOCK_BOOT="${1:-}"
ROOTED_BOOT="${2:-}"

if [ -z "$STOCK_BOOT" ]; then
    echo "Usage: $0 <path_to_stock_boot.img> [path_to_output_boot_magisk.img]"
    exit 1
fi

if [ ! -f "$STOCK_BOOT" ]; then
    echo "[-] Error: Stock boot image does not exist: $STOCK_BOOT"
    exit 1
fi

if [ -z "$ROOTED_BOOT" ]; then
    BOOT_DIR="$(dirname "$STOCK_BOOT")"
    BOOT_NAME="$(basename "$STOCK_BOOT" .img)"
    ROOTED_BOOT="$BOOT_DIR/${BOOT_NAME}-magisk.img"
fi

echo "============================================================"
echo "=== AVIUMUI MAGISK BOOT GENERATION ==="
echo "============================================================"
echo "[+] Stock Boot:  $STOCK_BOOT"
echo "[+] Rooted Boot: $ROOTED_BOOT"

MAGISKBOOT="$TOOLS_DIR/magiskboot_x86_64"
MAGISKINIT="$TOOLS_DIR/magiskinit_arm64"
MAGISK="$TOOLS_DIR/magisk_arm64"
INITLD="$TOOLS_DIR/init-ld_arm64"
STUB="$TOOLS_DIR/stub.apk"

for tool in "$MAGISKBOOT" "$MAGISKINIT" "$MAGISK" "$INITLD" "$STUB"; do
    if [ ! -f "$tool" ]; then
        echo "[-] Error: Required Magisk tool component not found: $tool"
        exit 1
    fi
done

chmod +x "$MAGISKBOOT"

STOCK_SIZE=$(stat -c%s "$STOCK_BOOT")
STOCK_SHA256=$(sha256sum "$STOCK_BOOT" | awk '{print $1}')
echo "[+] Stock boot size: $STOCK_SIZE bytes, sha256: $STOCK_SHA256"

WORK_DIR=$(mktemp -d -t avium_magisk_patch_XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT

cd "$WORK_DIR"

echo "[+] Unpacking stock boot image..."
"$MAGISKBOOT" unpack "$STOCK_BOOT"

if [ ! -f "ramdisk.cpio" ]; then
    echo "[-] Error: ramdisk.cpio not found after unpacking $STOCK_BOOT"
    exit 1
fi

echo "[+] Auditing ramdisk initial status..."
RAMDISK_STATUS=0
"$MAGISKBOOT" cpio ramdisk.cpio test || RAMDISK_STATUS=$?

if [ "$RAMDISK_STATUS" -ne 0 ]; then
    echo "[-] Warning: Ramdisk test returned status $RAMDISK_STATUS (expected 0: stock)"
    if [ "$RAMDISK_STATUS" -eq 1 ]; then
        echo "[!] Stock boot appears already patched by Magisk!"
    fi
fi

echo "[+] Compressing Magisk payloads for ramdisk inclusion..."
"$MAGISKBOOT" compress=xz "$MAGISK" magisk.xz
"$MAGISKBOOT" compress=xz "$STUB" stub.xz
"$MAGISKBOOT" compress=xz "$INITLD" init-ld.xz

SHA1=$("$MAGISKBOOT" sha1 "$STOCK_BOOT" 2>/dev/null || echo "")

export KEEPVERITY=true
export KEEPFORCEENCRYPT=true
export PATCHVBMETAFLAG=false
export RECOVERYMODE=false

cat << EOF > config
KEEPVERITY=true
KEEPFORCEENCRYPT=true
RECOVERYMODE=false
VENDORBOOT=false
PREINITDEVICE=persist
SHA1=$SHA1
EOF

cp -af ramdisk.cpio ramdisk.cpio.orig

echo "[+] Injecting magiskinit, overlay.d, and runtime configurations..."
"$MAGISKBOOT" cpio ramdisk.cpio \
    "add 0750 init $MAGISKINIT" \
    "mkdir 0750 overlay.d" \
    "mkdir 0750 overlay.d/sbin" \
    "add 0644 overlay.d/sbin/magisk.xz magisk.xz" \
    "add 0644 overlay.d/sbin/stub.xz stub.xz" \
    "add 0644 overlay.d/sbin/init-ld.xz init-ld.xz" \
    "patch" \
    "backup ramdisk.cpio.orig" \
    "mkdir 000 .backup" \
    "add 000 .backup/.magisk config"

echo "[+] Repacking boot image..."
"$MAGISKBOOT" repack "$STOCK_BOOT" "$ROOTED_BOOT"

if [ ! -f "$ROOTED_BOOT" ]; then
    echo "[-] Error: Failed to generate rooted boot image: $ROOTED_BOOT"
    exit 1
fi

ROOTED_SIZE=$(stat -c%s "$ROOTED_BOOT")
ROOTED_SHA256=$(sha256sum "$ROOTED_BOOT" | awk '{print $1}')

echo "============================================================"
echo "=== VERIFICATION & INTEGRITY CHECK ==="
echo "============================================================"
echo "[+] Stock  Boot: $STOCK_SIZE bytes | sha256: $STOCK_SHA256"
echo "[+] Rooted Boot: $ROOTED_SIZE bytes | sha256: $ROOTED_SHA256"

if [ "$STOCK_SIZE" -ne "$ROOTED_SIZE" ]; then
    echo "[!] Warning: Size difference detected ($STOCK_SIZE vs $ROOTED_SIZE bytes)"
fi

# Verify rooted boot ramdisk status
VERIFY_DIR=$(mktemp -d -t avium_magisk_verify_XXXXXX)
pushd "$VERIFY_DIR" > /dev/null
"$MAGISKBOOT" unpack "$ROOTED_BOOT" > /dev/null
VERIFY_STATUS=0
"$MAGISKBOOT" cpio ramdisk.cpio test > /dev/null 2>&1 || VERIFY_STATUS=$?
popd > /dev/null
rm -rf "$VERIFY_DIR"

if [ "$VERIFY_STATUS" -eq 1 ]; then
    echo "[PASS] Rooted boot verification succeeded (magiskboot status: 1 [Magisk Patched])"
else
    echo "[-] Error: Verification failed, expected status 1, got $VERIFY_STATUS"
    exit 1
fi

echo "[SUCCESS] AviumUI rooted boot successfully generated: $ROOTED_BOOT"
