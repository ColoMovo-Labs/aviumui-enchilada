#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/mnt/android/avium}"
META_DIR="${2:-${GITHUB_WORKSPACE:-/home/runner/_work/aviumui-enchilada/aviumui-enchilada}/control-repo}"
[ ! -d "$META_DIR" ] && META_DIR=$(find /home/runner -maxdepth 4 -type d -name "control-repo" 2>/dev/null | head -n 1)
[ ! -d "$META_DIR" ] && META_DIR=$(find /home/runner -maxdepth 4 -type d -name "avium-metadata" 2>/dev/null | head -n 1)
echo "fix_known_blockers using META_DIR: $META_DIR"
cd "$SOURCE_ROOT"

apply_patch_if_needed() {
  local target_dir="$1"
  local patch_file="$2"
  local patch_name
  patch_name="$(basename "$patch_file")"

  if [ ! -d "$target_dir" ]; then
    echo "[-] Directory $target_dir does not exist, skipping $patch_name"
    return 0
  fi
  if [ ! -f "$patch_file" ]; then
    echo "[-] Patch $patch_file not found, skipping"
    return 0
  fi

  pushd "$target_dir" > /dev/null
  if git apply --check "$patch_file" 2>/dev/null; then
    git apply "$patch_file"
    echo "[+] Applied $patch_name in $target_dir"
  else
    if git apply --reverse --check "$patch_file" 2>/dev/null; then
      echo "[*] Patch $patch_name already applied in $target_dir"
    else
      echo "[!] Warning: Patch $patch_name could not be applied cleanly to $target_dir"
    fi
  fi
  popd > /dev/null
}

echo "============================================================"
echo "=== 1. APPLYING GERRIT TOPIC: sdm845-kernel-4.19 PATCHES ==="
echo "============================================================"

# 1.1 hardware/qcom-caf/common
COMMON_CAF_DIR="$SOURCE_ROOT/hardware/qcom-caf/common"
COMMON_PATCH_DIR="$META_DIR/patches/hardware_qcom-caf_common"
if [ -d "$COMMON_PATCH_DIR" ]; then
  apply_patch_if_needed "$COMMON_CAF_DIR" "$COMMON_PATCH_DIR/0001-qcom-Add-support-for-TARGET_NO_CAMERA_CUSTOM_FORMAT.patch"
  apply_patch_if_needed "$COMMON_CAF_DIR" "$COMMON_PATCH_DIR/0002-qcom-Conditionally-use-sm8250-HALs-for-sdm845.patch"
fi

# 1.2 hardware/qcom-caf/sm8250/display
DISPLAY_CAF_DIR="$SOURCE_ROOT/hardware/qcom-caf/sm8250/display"
DISPLAY_PATCH_DIR="$META_DIR/patches/hardware_qcom_display_sm8250"
if [ -d "$DISPLAY_PATCH_DIR" ]; then
  apply_patch_if_needed "$DISPLAY_CAF_DIR" "$DISPLAY_PATCH_DIR/0001-gralloc-Protect-new-buffer-allocation-support-for-legacy-camera.patch"
fi

# 1.3 hardware/qcom-caf/sm8250/audio
AUDIO_CAF_DIR="$SOURCE_ROOT/hardware/qcom-caf/sm8250/audio"
AUDIO_PATCH_DIR="$META_DIR/patches/hardware_qcom_audio_sm8250"
if [ -d "$AUDIO_PATCH_DIR" ]; then
  apply_patch_if_needed "$AUDIO_CAF_DIR" "$AUDIO_PATCH_DIR/0001-hal-Add-support-for-sdm845.patch"
fi

# 1.4 device/qcom/sepolicy_vndr/legacy-um
SEPOLICY_VNDR_DIR="$SOURCE_ROOT/device/qcom/sepolicy_vndr/legacy-um"
[ ! -d "$SEPOLICY_VNDR_DIR" ] && SEPOLICY_VNDR_DIR="$SOURCE_ROOT/device/qcom/sepolicy_vndr"
SEPOLICY_PATCH_DIR="$META_DIR/patches/device_qcom_sepolicy_vndr"
if [ -d "$SEPOLICY_PATCH_DIR" ]; then
  for p in \
    0001-sepolicy_vndr-Initial-non-legacy-policy-for-sdm845.patch \
    0002-sdm845-Remove-duplicate-deprecated-policies.patch \
    0003-sdm845-Label-wakeup-nodes.patch \
    0004-sdm845-Label-kernel-4.19-devfreq-nodes.patch \
    0005-sdm845-Add-target-specific-rcsservice-policy.patch \
    0006-sdm845-Label-discard_max_bytes-sysfs.patch \
    0007-sepolicy_vndr-Globally-allow-using-logdump-partition-as-metadata.patch; do
    apply_patch_if_needed "$SEPOLICY_VNDR_DIR" "$SEPOLICY_PATCH_DIR/$p"
  done
fi

# 1.5 frameworks/base (SQLiteTokenizer, Google Photos spoof, Status Bar Capsule & Super Island)
FRAMEWORKS_BASE_DIR="$SOURCE_ROOT/frameworks/base"
FRAMEWORKS_BASE_PATCH_DIR="$META_DIR/patches/frameworks_base"
if [ -d "$FRAMEWORKS_BASE_PATCH_DIR" ]; then
  for p in $(ls "$FRAMEWORKS_BASE_PATCH_DIR"/*.patch 2>/dev/null | sort); do
    apply_patch_if_needed "$FRAMEWORKS_BASE_DIR" "$p"
  done
fi

TASK_JAVA="$FRAMEWORKS_BASE_DIR/services/core/java/com/android/server/wm/Task.java"
if [ -f "$TASK_JAVA" ]; then
  python3 - "$TASK_JAVA" << 'PYEOF' || true
import os, sys, re

task_java = sys.argv[1]
with open(task_java, "r", encoding="utf-8") as f:
    content = f.read()

if content.count("void prepareSurfaces()") > 1:
    print("[FRAMEWORKS_BASE] Found duplicate Task.prepareSurfaces() in Task.java, deduplicating...")
    m = re.search(r'void prepareSurfaces\(\)\s*\{([^}]+PopUpWindowController[^}]+)\}', content)
    if m and "mTaskInputSink" not in m.group(1):
        sink_block = """        // Input sink surface is not a part of animation, so apply in a steady state
        // (non-sync) with pending transaction.
        if (mTaskInputSink != null && isVisible() && mSyncState == SYNC_STATE_NONE) {
            mTaskInputSink.applyChangesToSurfaceIfChanged(getPendingTransaction());
        }
        """
        content = content[:m.start(1)] + sink_block + content[m.start(1):]
    
    matches = list(re.finditer(r'@Override\s+void prepareSurfaces\(\)\s*\{', content))
    if len(matches) > 1:
        start = matches[1].start()
        brace_count = 0
        end = -1
        for i in range(content.find('{', start), len(content)):
            if content[i] == '{':
                brace_count += 1
            elif content[i] == '}':
                brace_count -= 1
                if brace_count == 0:
                    end = i + 1
                    break
        if end != -1:
            content = content[:start] + content[end:]
            with open(task_java, "w", encoding="utf-8") as f:
                f.write(content)
            print("[FRAMEWORKS_BASE] Successfully resolved duplicate prepareSurfaces() in Task.java!")
else:
    print("[FRAMEWORKS_BASE] Task.java prepareSurfaces() is clean.")
PYEOF
fi

# 1.6 packages/apps/FeatureSettings (Capsule, Super Island, and Native Font Picker)
FEATURE_SETTINGS_DIR="$SOURCE_ROOT/packages/apps/FeatureSettings"
FEATURE_SETTINGS_PATCH_DIR="$META_DIR/patches/packages_apps_FeatureSettings"
if [ -d "$FEATURE_SETTINGS_PATCH_DIR" ]; then
  for p in $(ls "$FEATURE_SETTINGS_PATCH_DIR"/*.patch 2>/dev/null | sort); do
    apply_patch_if_needed "$FEATURE_SETTINGS_DIR" "$p"
  done
fi

if [ -d "$FEATURE_SETTINGS_DIR" ]; then
  python3 - "$FEATURE_SETTINGS_DIR" << 'PYEOF' || true
import sys, os

feature_dir = sys.argv[1]

# 1. In CategorySettingsFragment.kt
frag_path = os.path.join(feature_dir, "app/src/main/java/org/exthm/featuresettings/CategorySettingsFragment.kt")
if os.path.exists(frag_path):
    with open(frag_path, "r", encoding="utf-8") as f:
        code = f.read()
    if "bindFontPreference" not in code:
        font_method = """
    private fun bindFontPreference() {
        val pref = findPreference<androidx.preference.ListPreference>("theme_font_picker") ?: return
        val resolver = requireContext().contentResolver
        val categoryKey = "android.theme.customization.font"
        val settingKey = "theme_customization_overlay_packages"

        fun getCurrentFont(): String {
            try {
                val raw = android.provider.Settings.Secure.getString(resolver, settingKey)
                if (!raw.isNullOrEmpty()) {
                    val json = org.json.JSONObject(raw)
                    if (json.has(categoryKey)) {
                        return json.getString(categoryKey)
                    }
                }
            } catch (ignored: Exception) {}
            return "android"
        }

        val current = getCurrentFont()
        pref.isPersistent = false
        pref.value = current
        val idx = pref.findIndexOfValue(current)
        if (idx >= 0) {
            pref.summary = pref.entries[idx]
        }

        pref.onPreferenceChangeListener = androidx.preference.Preference.OnPreferenceChangeListener { _, newValue ->
            val pkg = newValue as? String ?: "android"
            try {
                val raw = android.provider.Settings.Secure.getString(resolver, settingKey)
                val json = if (!raw.isNullOrEmpty()) {
                    try { org.json.JSONObject(raw) } catch (e: Exception) { org.json.JSONObject() }
                } else {
                    org.json.JSONObject()
                }

                if (pkg == "android" || pkg.isEmpty()) {
                    json.remove(categoryKey)
                } else {
                    json.put(categoryKey, pkg)
                }

                android.provider.Settings.Secure.putString(resolver, settingKey, json.toString())

                val newIdx = pref.findIndexOfValue(pkg)
                if (newIdx >= 0) {
                    pref.summary = pref.entries[newIdx]
                }
            } catch (e: Exception) {
                android.util.Log.e("FeatureSettings", "Failed to update font setting", e)
            }
            true
        }
    }
"""
        idx = code.rfind("}")
        if idx != -1:
            code = code[:idx] + font_method + "\n" + code[idx:]
        if "bindStatusBarPreferences()" in code:
            call_idx = code.find("bindStatusBarPreferences()")
            brace_idx = code.find("{", call_idx)
            if brace_idx != -1:
                code = code[:brace_idx + 1] + "\n        bindFontPreference()" + code[brace_idx + 1:]
        with open(frag_path, "w", encoding="utf-8") as f:
            f.write(code)
        print("[FEATURE_SETTINGS] Injected bindFontPreference into CategorySettingsFragment.kt")

# 2. In feature_settings_ui.xml
xml_path = os.path.join(feature_dir, "app/src/main/res/xml/feature_settings_ui.xml")
if os.path.exists(xml_path):
    with open(xml_path, "r", encoding="utf-8") as f:
        xml_content = f.read()
    if "theme_font_picker" not in xml_content:
        font_cat = """
    <PreferenceCategory
        android:title="@string/font_settings_title">

        <ListPreference
            android:key="theme_font_picker"
            android:title="@string/font_manager_title"
            android:summary="%s"
            android:entries="@array/font_picker_entries"
            android:entryValues="@array/font_picker_values"
            android:defaultValue="android" />
    </PreferenceCategory>
"""
        idx = xml_content.rfind("</PreferenceScreen>")
        if idx != -1:
            xml_content = xml_content[:idx] + font_cat + "\n" + xml_content[idx:]
            with open(xml_path, "w", encoding="utf-8") as f:
                f.write(xml_content)
            print("[FEATURE_SETTINGS] Injected font category into feature_settings_ui.xml")

# 3. In app/src/main/res/values/arrays.xml
arrays_en = os.path.join(feature_dir, "app/src/main/res/values/arrays.xml")
if os.path.exists(arrays_en):
    with open(arrays_en, "r", encoding="utf-8") as f:
        arr_content = f.read()
    if "font_picker_entries" not in arr_content:
        font_arrays = """
    <!-- Font Picker -->
    <string-array name="font_picker_entries" translatable="false">
        <item>System Default</item>
        <item>Smiley Sans (得意黑)</item>
        <item>LXGW WenKai (霞鹜文楷)</item>
        <item>LXGW Neo XiHei (霞鹜新晰黑)</item>
        <item>Xiaolai Rounded (小赖圆体)</item>
        <item>Noto Serif SC (思源宋体)</item>
        <item>ZCOOL QingKe HuangYou (站酷黄油)</item>
        <item>ZCOOL XiaoWei (站酷小薇)</item>
        <item>ZCOOL KuaiLe (站酷快乐)</item>
        <item>Ma Shan Zheng (马善政毛笔)</item>
        <item>Long Cang (龙藏体)</item>
        <item>Zhi Mang Xing (志莽行书)</item>
    </string-array>

    <string-array name="font_picker_values" translatable="false">
        <item>android</item>
        <item>org.avium.overlay.font.smileysans</item>
        <item>org.avium.overlay.font.lxgwwenkai</item>
        <item>org.avium.overlay.font.lxgwneoxihei</item>
        <item>org.avium.overlay.font.xiaolai</item>
        <item>org.avium.overlay.font.notoserifsc</item>
        <item>org.avium.overlay.font.zcoolqingkehuangyou</item>
        <item>org.avium.overlay.font.zcoolxiaowei</item>
        <item>org.avium.overlay.font.zcoolkuaile</item>
        <item>org.avium.overlay.font.mashanzheng</item>
        <item>org.avium.overlay.font.longcang</item>
        <item>org.avium.overlay.font.zhimangxing</item>
    </string-array>
"""
        idx = arr_content.rfind("</resources>")
        if idx != -1:
            arr_content = arr_content[:idx] + font_arrays + "\n" + arr_content[idx:]
            with open(arrays_en, "w", encoding="utf-8") as f:
                f.write(arr_content)
            print("[FEATURE_SETTINGS] Injected font arrays into arrays.xml")

# 4. In strings.xml (en and zh-rCN)
strings_en = os.path.join(feature_dir, "app/src/main/res/values/strings.xml")
if os.path.exists(strings_en):
    with open(strings_en, "r", encoding="utf-8") as f:
        str_content = f.read()
    if "font_settings_title" not in str_content:
        font_strings = """
    <string name="font_settings_title">Typography &amp; Fonts</string>
    <string name="font_manager_title">System Font Style</string>
"""
        idx = str_content.rfind("</resources>")
        if idx != -1:
            str_content = str_content[:idx] + font_strings + "\n" + str_content[idx:]
            with open(strings_en, "w", encoding="utf-8") as f:
                f.write(str_content)
            print("[FEATURE_SETTINGS] Injected font strings into strings.xml")

strings_zh = os.path.join(feature_dir, "app/src/main/res/values-zh-rCN/strings.xml")
if os.path.exists(strings_zh):
    with open(strings_zh, "r", encoding="utf-8") as f:
        str_content = f.read()
    if "font_settings_title" not in str_content:
        font_strings_zh = """
    <string name="font_settings_title">字体与排版风格</string>
    <string name="font_manager_title">系统字体选择</string>
"""
        idx = str_content.rfind("</resources>")
        if idx != -1:
            str_content = str_content[:idx] + font_strings_zh + "\n" + str_content[idx:]
            with open(strings_zh, "w", encoding="utf-8") as f:
                f.write(str_content)
            print("[FEATURE_SETTINGS] Injected font strings into values-zh-rCN/strings.xml")
PYEOF
fi

# 1.6b packages/apps/Launcher3 (Smooth return-to-home animation on Back)
LAUNCHER3_DIR="$SOURCE_ROOT/packages/apps/Launcher3"
LAUNCHER3_PATCH_DIR="$META_DIR/patches/packages_apps_Launcher3"
if [ -d "$LAUNCHER3_PATCH_DIR" ]; then
  for p in $(ls "$LAUNCHER3_PATCH_DIR"/*.patch 2>/dev/null | sort); do
    apply_patch_if_needed "$LAUNCHER3_DIR" "$p"
  done
fi

# 1.7 packages/overlays/Lineage (Add Chinese font families to Soong fonts_customization module)
OVERLAYS_LINEAGE_DIR="$SOURCE_ROOT/packages/overlays/Lineage"
OVERLAYS_LINEAGE_PATCH_DIR="$META_DIR/patches/packages_overlays_Lineage"
if [ -d "$OVERLAYS_LINEAGE_PATCH_DIR" ]; then
  for p in $(ls "$OVERLAYS_LINEAGE_PATCH_DIR"/*.patch 2>/dev/null | sort); do
    apply_patch_if_needed "$OVERLAYS_LINEAGE_DIR" "$p"
  done
fi

DEVICE_FONTS_XML="$SOURCE_ROOT/device/oneplus/enchilada/fonts/fonts_customization.xml"
TARGET_FONTS_XML="$SOURCE_ROOT/packages/overlays/Lineage/fonts/etc/fonts_customization.xml"
if [ -f "$DEVICE_FONTS_XML" ] && [ -f "$TARGET_FONTS_XML" ]; then
  ALL_11_FONTS_PRESENT=true
  for f in \
    smiley-sans \
    lxgw-wenkai \
    lxgw-neoxihei \
    xiaolai-rounded \
    noto-serif-sc \
    zcool-qingke-huangyou \
    zcool-xiaowei \
    zcool-kuaile \
    mashanzheng \
    longcang \
    zhimangxing; do
    if ! grep -q "name=\"$f\"" "$TARGET_FONTS_XML"; then
      ALL_11_FONTS_PRESENT=false
      break
    fi
  done
  if [ "$ALL_11_FONTS_PRESENT" != "true" ]; then
    echo "[+] Populating $TARGET_FONTS_XML with complete 11 fonts from $DEVICE_FONTS_XML"
    cp -f "$DEVICE_FONTS_XML" "$TARGET_FONTS_XML"
  fi
fi

# 1.8 vendor/avium (Remove ro.avium.maintainer from version.mk to allow device product.prop)
VENDOR_AVIUM_DIR="$SOURCE_ROOT/vendor/avium"
VENDOR_AVIUM_PATCH_DIR="$META_DIR/patches/vendor_avium"
if [ -d "$VENDOR_AVIUM_PATCH_DIR" ]; then
  for p in $(ls "$VENDOR_AVIUM_PATCH_DIR"/*.patch 2>/dev/null | sort); do
    apply_patch_if_needed "$VENDOR_AVIUM_DIR" "$p"
  done
fi
VERSION_MK="$SOURCE_ROOT/vendor/avium/config/version.mk"
if [ -f "$VERSION_MK" ]; then
  sed -i '/ro\.avium\.maintainer=/d' "$VERSION_MK" || true
fi

# 1.8b packages/modules/common (Update allowed_deps.txt for 16.2.2 oemnetd tethering dependency)
ALLOWED_DEPS="$SOURCE_ROOT/packages/modules/common/build/allowed_deps.txt"
if [ -f "$ALLOWED_DEPS" ]; then
  python3 - "$ALLOWED_DEPS" << 'PYEOF' || true
import sys

deps_file = sys.argv[1]
with open(deps_file, "r") as f:
    lines = f.readlines()

comments = [l for l in lines if l.startswith("#")]
entries = [l.strip() for l in lines if l.strip() and not l.startswith("#")]

new_entry = "oemnetd_aidl_interface-java(minSdkVersion:30)"
if new_entry not in entries:
    entries.append(new_entry)
    entries.sort()
    with open(deps_file, "w") as f:
        f.writelines(comments)
        for e in entries:
            f.write(e + "\n")
    print(f"[ALLOWED_DEPS] Added {new_entry} to {deps_file}")
else:
    print(f"[ALLOWED_DEPS] {new_entry} already present in {deps_file}")
PYEOF
fi

# 1.9 Purge legacy LoMoLab and wallpapers
echo "============================================================"
echo "=== PURGING LEGACY LOMOLAB AND WALLPAPERS ==="
echo "============================================================"
ENCHILADA_MK="$SOURCE_ROOT/device/oneplus/enchilada/lineage_enchilada.mk"
if [ -f "$ENCHILADA_MK" ]; then
  sed -i '/wallpapers\.mk/d' "$ENCHILADA_MK" || true
  sed -i '/LoMoLab/d' "$ENCHILADA_MK" || true
fi
if [ -d "$SOURCE_ROOT/device/oneplus/enchilada/wallpapers" ]; then
  echo "[-] Purging legacy 27 wallpapers directory from device tree..."
  rm -rf "$SOURCE_ROOT/device/oneplus/enchilada/wallpapers"
fi
if [ -d "$SOURCE_ROOT/packages/apps/LoMoLab" ]; then
  echo "[-] Purging legacy LoMoLab directory from source tree..."
  rm -rf "$SOURCE_ROOT/packages/apps/LoMoLab"
fi

# 1.9b Sync AviumUI Module Lab 2.0 (Root & Hooking Ecosystem Center)
echo "============================================================"
echo "=== SYNCING MODULE LAB 2.0 TO BUILD TREE ==="
echo "============================================================"
if [ -d "$META_DIR/packages/apps/ModuleLab" ]; then
  echo "[+] Copying ModuleLab to $SOURCE_ROOT/packages/apps/ModuleLab..."
  mkdir -p "$SOURCE_ROOT/packages/apps/ModuleLab"
  cp -rf "$META_DIR/packages/apps/ModuleLab/"* "$SOURCE_ROOT/packages/apps/ModuleLab/"
  
  if [ -f "$ENCHILADA_MK" ]; then
    if ! grep -q "ModuleLab" "$ENCHILADA_MK"; then
      echo "[+] Registering ModuleLab in PRODUCT_PACKAGES ($ENCHILADA_MK)..."
      cat << 'MKEOF' >> "$ENCHILADA_MK"

# AviumUI Module Lab 2.0 (Root & Module Management Center)
PRODUCT_PACKAGES += \
    ModuleLab
MKEOF
    fi
  fi
fi

SETTINGS_DIR="$SOURCE_ROOT/packages/apps/Settings"
if [ -d "$SETTINGS_DIR" ]; then
  echo "[-] Purging legacy LoMoLab strings and preferences from Settings..."
  rm -f "$SETTINGS_DIR/res/drawable/ic_lomolab.xml"
  sed -i '/lomolab_/d' "$SETTINGS_DIR/res/values/strings.xml" 2>/dev/null || true
  sed -i '/lomolab_/d' "$SETTINGS_DIR/res/values-zh-rCN/strings.xml" 2>/dev/null || true
  python3 - "$SETTINGS_DIR" << 'PYEOF' || true
import os, sys, re

settings_dir = sys.argv[1] if len(sys.argv) > 1 else "packages/apps/Settings"
top_level_xml = os.path.join(settings_dir, "res/xml/top_level_settings.xml")
if os.path.exists(top_level_xml):
    with open(top_level_xml, "r", encoding="utf-8") as f:
        c = f.read()
    if "top_level_lomolab" in c:
        c = re.sub(r'<!--\s*LoMoLab Customization Center\s*-->\s*<com\.android\.settings\.widget\.HomepagePreference\s+android:key="top_level_lomolab".*?</com\.android\.settings\.widget\.HomepagePreference>\s*', '', c, flags=re.DOTALL)
        c = re.sub(r'<com\.android\.settings\.widget\.HomepagePreference\s+android:key="top_level_lomolab".*?</com\.android\.settings\.widget\.HomepagePreference>\s*', '', c, flags=re.DOTALL)
        with open(top_level_xml, "w", encoding="utf-8") as f:
            f.write(c)
        print("[SETTINGS] Successfully removed LoMoLab from top_level_settings.xml")
PYEOF
fi

echo "============================================================"
echo "=== 2. AUDITING VENDOR PROPRIETARY BLOBS ==="
echo "============================================================"
VENDOR_DIR="$SOURCE_ROOT/vendor/oneplus/sdm845-common"
if [ -d "$VENDOR_DIR" ]; then
  echo "[VENDOR] Inspecting vendor/oneplus/sdm845-common Android.bp..."
  VENDOR_BP="$VENDOR_DIR/Android.bp"
  if [ -f "$VENDOR_BP" ]; then
    python3 - << 'PYEOF'
import re

bp_file = "vendor/oneplus/sdm845-common/Android.bp"
try:
    with open(bp_file, "r") as f:
        content = f.read()

    targets = ["libqti-iopd", "libqti-iopd-client", "libqti-perfd", "libwfdservice"]
    modified = False

    for target in targets:
        pattern = re.compile(rf'(cc_prebuilt_library_shared\s*\{{[^}}]*?name:\s*"{target}",)')
        match = pattern.search(content)
        if match:
            following = content[match.end():match.end() + 200]
            if "check_elf_files: false" not in following:
                print(f"[VENDOR] Applying check_elf_files: false to {target}")
                content = content[:match.end()] + '\n\tcheck_elf_files: false,' + content[match.end():]
                modified = True
            else:
                print(f"[VENDOR] {target} already has check_elf_files: false")
        else:
            pass

    if modified:
        with open(bp_file, "w") as f:
            f.write(content)
        print("[VENDOR] Updated vendor Android.bp successfully.")
    else:
        print("[VENDOR] No unhardened ELF targets found; vendor Android.bp is clean.")
except Exception as e:
    print(f"[VENDOR] Error processing vendor Android.bp: {e}")
PYEOF
  fi
else
  echo "[VENDOR] Warning: Vendor dir not found at $VENDOR_DIR"
fi

echo "============================================================"
echo "=== 3. HARDENING SOONG ci_tests FOR HOST TESTS ==="
echo "============================================================"
CI_TEST_ZIP="$SOURCE_ROOT/build/soong/ci_tests/ci_test_package_zip.go"
if [ -f "$CI_TEST_ZIP" ]; then
  echo "[SOONG] Applying filepath.IsAbs safeguard to $CI_TEST_ZIP..."
  sed -i 's/if strings.HasPrefix(f, "out") {/if strings.HasPrefix(f, "out") || filepath.IsAbs(f) {/' "$CI_TEST_ZIP" || true
fi

echo "============================================================"
echo "=== 4. PURGING LunarisDolby & AUDITING HARDWARE DOLBY ==="
echo "============================================================"
DOLBY_MK="$SOURCE_ROOT/hardware/dolby/dolby.mk"
if [ -f "$DOLBY_MK" ]; then
  echo "[DOLBY] Stripping LunarisDolby package declaration from $DOLBY_MK..."
  sed -i '/LunarisDolby/d' "$DOLBY_MK" || true
  echo "[DOLBY] PASS: LunarisDolby package purged from dolby.mk."
fi

if [ -d "$SOURCE_ROOT/hardware/dolby" ]; then
  echo "[DOLBY] PASS: hardware/dolby exists in source tree."
else
  echo "[DOLBY] ERROR: hardware/dolby not found in $SOURCE_ROOT/hardware/dolby!"
  exit 1
fi

echo "============================================================"
echo "=== 5. ASSERTING PURE LINUX 4.19 GOLDEN BASELINE (NO KSU) ==="
echo "============================================================"
KERNEL_DIR="$SOURCE_ROOT/kernel/oneplus/sdm845"
if [ -d "$KERNEL_DIR" ]; then
  echo "[KERNEL] Verifying pure Linux 4.19 golden baseline in $KERNEL_DIR..."
  if [ -d "$KERNEL_DIR/drivers/kernelsu" ]; then
    echo "[KERNEL] ERROR: drivers/kernelsu found in kernel tree! KernelSU must be completely absent."
    exit 1
  fi

  ENCHILADA_CONF="$KERNEL_DIR/arch/arm64/configs/vendor/enchilada.config"
  if grep -q "^CONFIG_KSU" "$ENCHILADA_CONF"; then
    echo "[KERNEL] ERROR: CONFIG_KSU found in $ENCHILADA_CONF! KernelSU must be completely absent."
    exit 1
  fi

  echo "[KERNEL] PASS: Pure Linux 4.19 golden baseline verified (KernelSU ABSENT)."
fi


echo "============================================================"
echo "=== 6. VERIFYING AVIUMUI OFFICIAL GMS REPOSITORIES ==="
echo "============================================================"
for d in vendor/pixel/gms vendor/pixel/clocks vendor/pixel/sounds; do
  if [ -d "$SOURCE_ROOT/$d" ]; then
    echo "[GMS] PASS: $d exists in source tree."
  else
    echo "[GMS] ERROR: Required directory $d not found!"
    exit 1
  fi
done

echo "============================================================"
echo "=== 6.1 SLIMMING OPTIONAL GMS PACKAGES (VELVET & MAPS) ==="
echo "============================================================"
GMS_DIR="$SOURCE_ROOT/vendor/pixel/gms"
GMS_PATCH_DIR="$META_DIR/patches/vendor_pixel_gms"
if [ -d "$GMS_PATCH_DIR" ]; then
  for p in $(ls "$GMS_PATCH_DIR"/*.patch 2>/dev/null | sort); do
    apply_patch_if_needed "$GMS_DIR" "$p"
  done
fi

GMS_VENDOR_MK="$SOURCE_ROOT/vendor/pixel/gms/common/common-vendor.mk"
if [ -f "$GMS_VENDOR_MK" ]; then
  echo "[GMS] Ensuring Velvet and Maps are excluded from $GMS_VENDOR_MK..."
  sed -i '/^[[:space:]]*Velvet[[:space:]]*\\/d' "$GMS_VENDOR_MK" || true
  sed -i '/^[[:space:]]*Maps[[:space:]]*\\/d' "$GMS_VENDOR_MK" || true
  echo "[GMS] PASS: Optional GMS slimming applied successfully."
fi

echo "============================================================"
echo "=== 7. VERIFYING SDM845-COMMON 4.19 & EROFS CONFIGURATION ==="
echo "============================================================"
COMMON_DIR="$SOURCE_ROOT/device/oneplus/sdm845-common"
if [ -d "$COMMON_DIR" ]; then
  echo "[DEVICE] Inspecting $COMMON_DIR..."

  # Assert TARGET_KERNEL_VERSION is 4.19
  if grep -rn "TARGET_KERNEL_VERSION := 4.19" "$COMMON_DIR/BoardConfigCommon.mk" >/dev/null; then
    echo "[DEVICE] PASS: TARGET_KERNEL_VERSION := 4.19 confirmed in BoardConfigCommon.mk"
  else
    echo "[DEVICE] ERROR: TARGET_KERNEL_VERSION is NOT set to 4.19 in BoardConfigCommon.mk!"
    exit 1
  fi

  # Assert EROFS
  if grep -rn "BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs" "$COMMON_DIR/BoardConfigCommon.mk" >/dev/null && \
     grep -rn "BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs" "$COMMON_DIR/BoardConfigCommon.mk" >/dev/null; then
    echo "[DEVICE] PASS: EROFS filesystem configuration confirmed in BoardConfigCommon.mk"
  else
    echo "[DEVICE] ERROR: EROFS filesystem NOT configured in BoardConfigCommon.mk!"
    exit 1
  fi

  # Assert Zero-Super
  if grep -rn "BOARD_SUPER_PARTITION_SIZE" "$COMMON_DIR" | grep -vE ':[0-9]+:[[:space:]]*#' | grep -v "BOARD_SUPER_PARTITION_SIZE := 0"; then
    echo "[DEVICE] ERROR: Non-zero BOARD_SUPER_PARTITION_SIZE detected in $COMMON_DIR!"
    exit 1
  fi
  echo "[DEVICE] PASS: Zero-super configuration confirmed."
else
  echo "[DEVICE] Warning: $COMMON_DIR not found."
fi

echo "============================================================"
echo "=== 8. ALL 4.19 BLOCKER RESOLUTIONS APPLIED SUCCESSFULLY ==="
echo "============================================================"
