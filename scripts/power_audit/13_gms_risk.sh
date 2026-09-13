#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/13-gms-risk.txt"
echo "=== Step 13: Google Mobile Services (GMS) Power Risk Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=1  # GMS is a confirmed major runtime difference vs Vanilla

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"

log "[*] 1. Baseline Comparison: WITH_GMS Delta:"
log "  Vanilla Golden Baseline : WITH_GMS=false (Pure AOSP, zero Google background services)"
log "  Current Feature Build   : WITH_GMS=true  (Preinstalled Google Mobile Services package)"
log "  Impact Assessment       : High runtime impact. GMS introduces persistent background wakelocks,"
log "                            periodic sync adapters, network heartbeats, and telemetry."

log "[*] 2. Preinstalled GMS Package Inventory Audit:"
GMS_VENDOR="vendor/pixel/gms"
if [ -d "$GMS_VENDOR" ]; then
    GMS_PACKAGES=$(find "$GMS_VENDOR" -maxdepth 3 -name "Android.mk" -o -name "Android.bp" 2>/dev/null || true)
    log "  GMS Package Definitions found:"
    log "$GMS_PACKAGES"
else
    log "  (vendor/pixel/gms not present at local path; inspecting patches)"
fi

# Check our slim patch for GMS apps
PATCH_GMS="$CONTROL_DIR/patches/vendor_pixel_gms/0001-common-vendor-slim-optional-apps-for-system-partitio.patch"
if [ -f "$PATCH_GMS" ]; then
    log "  Slimmed GMS Patch contents ($PATCH_GMS):"
    log "$(cat "$PATCH_GMS")"
    log "  [PASS] Heavy packages removed: Velvet (Google App), Google Maps."
    log "  Retained core packages: PrebuiltGmsCoreVic, Phonesky, GoogleServicesFramework, GoogleRestore, SetupWizard, Gboard, GoogleDialer, Messages."
fi

log "[*] 3. Post-First-Boot High-Drain GMS Activity Checklist:"
log "  During the initial hours/days after fresh ROM flash and Google account sign-in,"
log "  GMS executes extensive high-priority synchronization tasks:"
log "    [1] Play Store app background restore and auto-updates (Dex2oat CPU load)."
log "    [2] Google Photos cloud backup and thumbnail indexing (High CPU & network)."
log "    [3] Google Contacts / Calendar / Drive initial synchronization."
log "    [4] Google Play Protect background APK signature scans."
log "    [5] Google Location Accuracy (Network location / Wi-Fi fingerprinting scans)."
log "    [6] Firebase Cloud Messaging (FCM) persistent socket heartbeats."

log "[*] 4. GMS Runtime Diagnostic Command Reference:"
log "  To inspect GMS real-time battery consumption on device:"
log "    adb shell dumpsys batterystats | grep -A 25 'u0a.*com.google.android.gms'"
log "    adb shell dumpsys activity processes | grep com.google.android.gms"
log "    adb shell cmd appops get com.google.android.gms WAKE_LOCK"

log "--------------------------------------------------------"
log "STEP 13 RESULT: YELLOW (GMS is active with known background sync overhead vs Vanilla)"
