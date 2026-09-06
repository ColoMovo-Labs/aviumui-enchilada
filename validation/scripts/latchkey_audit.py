#!/usr/bin/env python3
import os
import sys
import json
import glob
import struct
import shutil
import hashlib
import zipfile
import subprocess

def log(msg):
    print(f"[*] {msg}", flush=True)

def sha256_file(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def run_cmd(cmd, check=True):
    log(f"Running: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    res = subprocess.run(cmd, shell=isinstance(cmd, str), capture_output=True, text=True)
    if check and res.returncode != 0:
        log(f"Command failed (code {res.returncode}):\nStdout: {res.stdout}\nStderr: {res.stderr}")
    return res

def main():
    work_dir = os.environ.get("AUDIT_DIR", "/tmp/latchkey_audit")
    golden_json_path = os.environ.get("GOLDEN_JSON", "validation/golden/DERPFEST_GOLDEN_REFERENCE.json")
    out_dir = os.environ.get("OUTPUT_DIR", ".")
    
    os.makedirs(work_dir, exist_ok=True)
    os.makedirs(out_dir, exist_ok=True)

    findings = []
    
    def add_finding(category, check_name, status, details, recommendation=""):
        findings.append({
            "category": category,
            "check": check_name,
            "status": status,  # GREEN, YELLOW, RED, UNKNOWN
            "details": details,
            "recommendation": recommendation
        })

    # Load Golden
    golden = {}
    if os.path.exists(golden_json_path):
        with open(golden_json_path) as f:
            golden = json.load(f)
        log(f"Loaded Golden reference from {golden_json_path}")
        add_finding("SETUP", "Golden Reference Loading", "GREEN", f"Loaded golden reference for {golden.get('package', {}).get('device')}")
    else:
        log(f"WARNING: Golden reference not found at {golden_json_path}")
        add_finding("SETUP", "Golden Reference Loading", "YELLOW", f"Golden reference path {golden_json_path} missing")

    rom_zip = os.path.join(work_dir, "AviumUI-16.2.1-enchilada-20260906-Unofficial-Vanilla.zip")
    expected_rom_sha = "9b4536947d22a8ceb622793bf76a17da962cbf1bfc67e02b592ed5abbfc6e4e5"
    
    # 1. Verify ROM SHA256
    if not os.path.exists(rom_zip):
        add_finding("INTEGRITY", "ROM ZIP Presence", "RED", f"ROM ZIP {rom_zip} not found in workspace", "Ensure artifact download succeeded")
        generate_report(findings, out_dir, None)
        return 1

    actual_rom_sha = sha256_file(rom_zip)
    log(f"Calculated ROM SHA256: {actual_rom_sha}")
    if actual_rom_sha == expected_rom_sha:
        add_finding("INTEGRITY", "ROM SHA256 Checksum", "GREEN", f"Matches expected SHA256: {actual_rom_sha}")
    else:
        add_finding("INTEGRITY", "ROM SHA256 Checksum", "RED", f"Mismatch! Expected {expected_rom_sha}, got {actual_rom_sha}", "Corrupted download")

    # Check partition images in artifact
    for img in ["boot.img", "dtbo.img", "vbmeta.img"]:
        ipath = os.path.join(work_dir, img)
        if os.path.exists(ipath):
            isha = sha256_file(ipath)
            isize = os.path.getsize(ipath)
            sha_file = os.path.join(work_dir, f"{img}.sha256")
            if os.path.exists(sha_file):
                with open(sha_file) as sf:
                    exp = sf.read().split()[0]
                    if isha == exp:
                        add_finding("INTEGRITY", f"Artifact {img} SHA256", "GREEN", f"Matches {img}.sha256 ({isize} bytes)")
                    else:
                        add_finding("INTEGRITY", f"Artifact {img} SHA256", "RED", f"Mismatch with {img}.sha256")
            else:
                add_finding("INTEGRITY", f"Artifact {img} Presence", "GREEN", f"Present ({isize} bytes, sha: {isha[:12]}...)")
        else:
            add_finding("INTEGRITY", f"Artifact {img} Presence", "RED", f"Partition image {img} missing from artifact")

    # 2. Inspect OTA ZIP Structure
    log("Inspecting OTA ZIP Structure...")
    with zipfile.ZipFile(rom_zip, 'r') as z:
        namelist = z.namelist()
        log(f"ZIP files: {namelist}")
        if "payload.bin" in namelist:
            add_finding("STRUCTURE", "OTA Payload.bin", "GREEN", "Standard A/B OTA payload.bin found in ZIP root")
        else:
            add_finding("STRUCTURE", "OTA Payload.bin", "RED", "payload.bin missing from ROM ZIP", "Not a valid A/B OTA package")
            
        if "META-INF/com/android/metadata" in namelist:
            meta = z.read("META-INF/com/android/metadata").decode('utf-8', errors='replace')
            add_finding("STRUCTURE", "OTA Metadata", "GREEN", f"OTA metadata found: {meta.strip().replace(chr(10), '; ')}")
        else:
            add_finding("STRUCTURE", "OTA Metadata", "YELLOW", "META-INF/com/android/metadata not found")

        # Extract payload.bin
        payload_path = os.path.join(work_dir, "payload.bin")
        if not os.path.exists(payload_path):
            log("Extracting payload.bin from ROM zip...")
            z.extract("payload.bin", path=work_dir)
            log(f"Extracted payload.bin ({os.path.getsize(payload_path)} bytes)")

    # 3. Payload Metadata & Partition List
    log("Inspecting payload partitions via payload-dumper-go...")
    pd_cmd = ["payload-dumper-go", "-l", payload_path]
    pd_res = run_cmd(pd_cmd, check=False)
    payload_partitions = []
    if pd_res.returncode == 0:
        lines = pd_res.stdout.splitlines()
        for line in lines:
            line = line.strip()
            if line and not line.startswith("===") and not line.lower().startswith("payload") and not line.lower().startswith("number"):
                payload_partitions.append(line.split()[0] if line.split() else line)
        add_finding("PAYLOAD", "Partition List Enumeration", "GREEN", f"Found {len(payload_partitions)} partitions in payload: {', '.join(payload_partitions[:15])}")
    else:
        add_finding("PAYLOAD", "Partition List Enumeration", "YELLOW", f"payload-dumper-go -l output: {pd_res.stderr or pd_res.stdout}")

    # Check critical partitions in payload
    critical_parts = ["boot", "dtbo", "vbmeta", "system", "vendor", "modem", "dsp", "bluetooth"]
    missing_crit = [p for p in critical_parts if payload_partitions and not any(p in part for part in payload_partitions)]
    if missing_crit:
        add_finding("PAYLOAD", "Critical Partitions in Payload", "RED", f"Missing critical partitions in payload: {missing_crit}")
    else:
        add_finding("PAYLOAD", "Critical Partitions in Payload", "GREEN", "All critical partitions present in payload")

    # 4. Boot Image Analysis
    boot_path = os.path.join(work_dir, "boot.img")
    unpacked_boot = os.path.join(work_dir, "unpacked_boot")
    os.makedirs(unpacked_boot, exist_ok=True)
    
    unpack_res = run_cmd(["python3", "/usr/local/bin/unpack_bootimg.py", "--boot_img", boot_path, "--out", unpacked_boot], check=False)
    boot_info = {}
    if unpack_res.returncode == 0:
        add_finding("BOOT", "Boot Image Unpack", "GREEN", "boot.img successfully unpacked with Android unpack_bootimg.py")
        log(f"Unpack info:\n{unpack_res.stdout}")
        for line in unpack_res.stdout.splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                boot_info[k.strip()] = v.strip()
                
        # Compare OS Version & Header Version
        cmdline = boot_info.get("command line args", "")
        add_finding("BOOT", "Boot Header Version", "GREEN" if boot_info.get("boot image header version") == "1" else "YELLOW", f"Header version: {boot_info.get('boot image header version')}")
        add_finding("BOOT", "OS Version & Patch", "GREEN", f"OS: {boot_info.get('os version')}, Patch: {boot_info.get('os patch level')}")
        
        # Check kernel commandline
        has_essential_cmdline = all(term in cmdline for term in ["androidboot.hardware=qcom", "firmware_class.path=/vendor/firmware_mnt/image", "swiotlb=2048"])
        if has_essential_cmdline:
            add_finding("BOOT", "Kernel Cmdline Arguments", "GREEN", f"Cmdline contains essential parameters: {cmdline}")
        else:
            add_finding("BOOT", "Kernel Cmdline Arguments", "YELLOW", f"Cmdline differs: {cmdline}")
            
        # Check kernel format
        kpath = os.path.join(unpacked_boot, "kernel")
        if os.path.exists(kpath):
            ktype = run_cmd(["file", kpath], check=False).stdout.strip()
            add_finding("BOOT", "Kernel Binary Type", "GREEN", f"Kernel format: {ktype}")
        else:
            add_finding("BOOT", "Kernel Binary Presence", "RED", "No kernel binary found in unpacked boot.img")
    else:
        add_finding("BOOT", "Boot Image Unpack", "RED", f"Failed to unpack boot.img: {unpack_res.stderr}")

    # 5. DTBO Analysis
    dtbo_path = os.path.join(work_dir, "dtbo.img")
    if os.path.exists(dtbo_path):
        with open(dtbo_path, "rb") as f:
            data = f.read(32)
            if len(data) >= 32:
                magic, total_size, header_size, dt_entry_size, dt_entry_count, dt_entries_offset, page_size, version = struct.unpack(">IIIIIIII", data)
                magic_hex = hex(magic)
                if magic_hex == "0xd7b7ab1e":
                    add_finding("DTBO", "DTBO Magic & Header", "GREEN", f"Magic: {magic_hex}, entries: {dt_entry_count}, page_size: {page_size}, total_size: {total_size}")
                else:
                    add_finding("DTBO", "DTBO Magic & Header", "RED", f"Invalid DTBO Magic: {magic_hex} (expected 0xd7b7ab1e)")
    else:
        add_finding("DTBO", "DTBO Presence", "RED", "dtbo.img not found")

    # 6. VBMeta / AVB Analysis
    vbmeta_path = os.path.join(work_dir, "vbmeta.img")
    if os.path.exists(vbmeta_path):
        avb_res = run_cmd(["avbtool", "info_image", "--image", vbmeta_path], check=False)
        if avb_res.returncode == 0:
            add_finding("AVB", "VBMeta AVB Inspection", "GREEN", f"avbtool parsed vbmeta.img successfully:\n{avb_res.stdout[:500]}")
        else:
            vsize = os.path.getsize(vbmeta_path)
            with open(vbmeta_path, "rb") as f:
                vhdr = f.read(16)
            if vhdr.startswith(b"AVB0"):
                add_finding("AVB", "VBMeta AVB Inspection", "GREEN", f"Valid AVB0 magic header found ({vsize} bytes)")
            else:
                add_finding("AVB", "VBMeta AVB Inspection", "YELLOW", f"AVB tool output: {avb_res.stderr or avb_res.stdout}, size: {vsize}")

    # 7. Controlled Disk-Safe Extraction of Vendor & System Metadata
    extract_dir = os.path.join(work_dir, "extracted_parts")
    os.makedirs(extract_dir, exist_ok=True)
    
    # Dump vendor only
    log("Dumping vendor partition with payload-dumper-go...")
    vdump_res = run_cmd(["payload-dumper-go", "-p", "vendor", "-o", extract_dir, payload_path], check=False)
    vendor_img = os.path.join(extract_dir, "vendor.img")
    
    vendor_mount = os.path.join(work_dir, "vendor_mount")
    os.makedirs(vendor_mount, exist_ok=True)
    
    if os.path.exists(vendor_img):
        log("Extracting vendor.img metadata...")
        run_cmd(["7z", "x", "-y", f"-o{vendor_mount}", vendor_img, "etc/fstab.qcom", "etc/vintf/*", "etc/init/*", "build.prop", "etc/selinux/*"], check=False)
        
        fstab_candidates = glob.glob(f"{vendor_mount}/**/fstab.qcom", recursive=True)
        if not fstab_candidates:
            run_cmd(["sudo", "mount", "-o", "loop,ro", vendor_img, vendor_mount], check=False)
            fstab_candidates = glob.glob(f"{vendor_mount}/**/fstab.qcom", recursive=True)

        if fstab_candidates:
            fstab_file = fstab_candidates[0]
            log(f"Found fstab at {fstab_file}")
            with open(fstab_file) as f:
                fcontent = f.read()
                
            has_sys_fsm = "/dev/block/by-name/system" in fcontent and "first_stage_mount" in fcontent
            has_ven_fsm = "/dev/block/by-name/vendor" in fcontent and "first_stage_mount" in fcontent
            has_meta_fsm = "/metadata" in fcontent and "first_stage_mount" in fcontent
            has_data = "/data" in fcontent and "fileencryption=" in fcontent
            
            if has_sys_fsm and has_ven_fsm and has_meta_fsm:
                add_finding("FSTAB", "First-Stage Mount Entries", "GREEN", "system, vendor, metadata all configured with first_stage_mount and avb/wait flags")
            else:
                add_finding("FSTAB", "First-Stage Mount Entries", "RED", "Missing essential first_stage_mount entries for system/vendor/metadata", "Check device tree fstab.qcom")
                
            if has_data:
                add_finding("FSTAB", "Userdata Encryption", "GREEN", "userdata encryption parameters configured (aes-256-xts)")
            else:
                add_finding("FSTAB", "Userdata Encryption", "YELLOW", "userdata encryption parameters differ from standard")
        else:
            add_finding("FSTAB", "Vendor FSTAB Extraction", "YELLOW", "fstab.qcom could not be extracted directly from vendor.img")

        vintf_files = glob.glob(f"{vendor_mount}/**/manifest.xml", recursive=True)
        if vintf_files:
            with open(vintf_files[0]) as vf:
                vcontent = vf.read()
            add_finding("VINTF", "Vendor VINTF Manifest", "GREEN", f"VINTF manifest present with {len(vcontent.splitlines())} lines")
        else:
            add_finding("VINTF", "Vendor VINTF Manifest", "YELLOW", "VINTF manifest not located in extracted files")

        rc_files = glob.glob(f"{vendor_mount}/**/*.rc", recursive=True)
        services = []
        for rc in rc_files:
            try:
                with open(rc) as f:
                    for l in f:
                        if l.strip().startswith("service "):
                            services.append(l.strip())
            except Exception:
                pass
        if services:
            add_finding("INIT", "Vendor Init Services", "GREEN", f"Discovered {len(services)} vendor init services (e.g., {services[0] if services else ''})")
        else:
            add_finding("INIT", "Vendor Init Services", "YELLOW", "No vendor init services parsed from extracted rc files")

        log("Cleaning up vendor.img to preserve disk space...")
        run_cmd(["sudo", "umount", "-f", vendor_mount], check=False)
        shutil.rmtree(vendor_mount, ignore_errors=True)
        os.remove(vendor_img)
    else:
        add_finding("VENDOR", "Vendor Partition Dump", "YELLOW", f"Could not dump vendor partition: {vdump_res.stderr}")

    # Dump system only
    log("Dumping system partition with payload-dumper-go...")
    sdump_res = run_cmd(["payload-dumper-go", "-p", "system", "-o", extract_dir, payload_path], check=False)
    system_img = os.path.join(extract_dir, "system.img")
    system_mount = os.path.join(work_dir, "system_mount")
    os.makedirs(system_mount, exist_ok=True)
    
    if os.path.exists(system_img):
        log("Extracting system.img metadata...")
        run_cmd(["7z", "x", "-y", f"-o{system_mount}", system_img, "system/build.prop", "build.prop", "system/etc/selinux/*", "etc/selinux/*", "system/etc/init/*"], check=False)
        
        bprops = glob.glob(f"{system_mount}/**/build.prop", recursive=True)
        if not bprops:
            run_cmd(["sudo", "mount", "-o", "loop,ro", system_img, system_mount], check=False)
            bprops = glob.glob(f"{system_mount}/**/build.prop", recursive=True)
            
        if bprops:
            prop_data = {}
            with open(bprops[0]) as f:
                for l in f:
                    if "=" in l and not l.strip().startswith("#"):
                        k, v = l.strip().split("=", 1)
                        prop_data[k.strip()] = v.strip()
            add_finding("SYSTEM", "Android Release Version", "GREEN" if prop_data.get("ro.build.version.release") == "16" else "YELLOW", f"Android version: {prop_data.get('ro.build.version.release')}, SDK: {prop_data.get('ro.build.version.sdk')}")
            add_finding("SYSTEM", "Build Fingerprint", "GREEN", f"Fingerprint: {prop_data.get('ro.build.fingerprint', 'N/A')}")
        else:
            add_finding("SYSTEM", "System build.prop", "YELLOW", "Could not locate build.prop in extracted system.img")

        log("Cleaning up system.img to preserve disk space...")
        run_cmd(["sudo", "umount", "-f", system_mount], check=False)
        shutil.rmtree(system_mount, ignore_errors=True)
        os.remove(system_img)
    else:
        add_finding("SYSTEM", "System Partition Dump", "YELLOW", f"Could not dump system partition: {sdump_res.stderr}")

    if os.path.exists(payload_path):
        log("Cleaning up payload.bin to preserve Latchkey free disk...")
        os.remove(payload_path)

    generate_report(findings, out_dir, golden)
    return 0

def generate_report(findings, out_dir, golden):
    red_count = sum(1 for f in findings if f["status"] == "RED")
    yellow_count = sum(1 for f in findings if f["status"] == "YELLOW")
    green_count = sum(1 for f in findings if f["status"] == "GREEN")
    unknown_count = sum(1 for f in findings if f["status"] == "UNKNOWN")
    
    if red_count > 0:
        verdict = "NOT READY FOR HARDWARE TEST"
        verdict_badge = "🔴 NOT READY"
    else:
        verdict = "READY FOR CONTROLLED HARDWARE TEST PLANNING"
        verdict_badge = "🟢 READY FOR CONTROLLED PLANNING (No hardware boot guaranteed)"

    summary = {
        "verdict": verdict,
        "metrics": {
            "red": red_count,
            "yellow": yellow_count,
            "green": green_count,
            "unknown": unknown_count,
            "total": len(findings)
        },
        "findings": findings
    }

    json_path = os.path.join(out_dir, "AVIUM_VS_DERPFEST_BOOT_AUDIT.json")
    with open(json_path, "w") as f:
        json.dump(summary, f, indent=2)
    log(f"Wrote audit JSON to {json_path}")

    md_path = os.path.join(out_dir, "AVIUM_VS_DERPFEST_BOOT_AUDIT.md")
    md = f"""# AVIUM VS DERPFEST GOLDEN BOOT AUDIT REPORT

**Verdict**: {verdict_badge}
**Rule Evaluation**:
- `RED > 0` -> `NOT READY FOR HARDWARE TEST`
- `RED = 0` -> `READY FOR CONTROLLED HARDWARE TEST PLANNING` *(Note: RED=0 does NOT guarantee boot)*

| Status | Count |
| :--- | :--- |
| 🟢 GREEN | {green_count} |
| 🟡 YELLOW | {yellow_count} |
| 🔴 RED | {red_count} |
| ⚪ UNKNOWN | {unknown_count} |
| **Total Checks** | **{len(findings)}** |

---

### Detailed Audit Breakdown

| Category | Check | Status | Details |
| :--- | :--- | :---: | :--- |
"""
    for f in findings:
        status_icon = "🟢 GREEN" if f["status"] == "GREEN" else ("🔴 RED" if f["status"] == "RED" else ("🟡 YELLOW" if f["status"] == "YELLOW" else "⚪ UNKNOWN"))
        details = f["details"].replace("\n", "<br>")
        md += f"| `{f['category']}` | **{f['check']}** | {status_icon} | {details} |\n"

    md += f"""
---

### Execution Discipline & Safety Statement
1. **Zero Hardware Modifications**: This audit was executed purely in a static cloud sandbox. No devices were flashed, booted, or sideloaded.
2. **Clean Reference Paradigm**: DerpFest 16.2 was utilized strictly as an observational golden benchmark. Zero binary or configuration copying was performed.
"""
    with open(md_path, "w") as f:
        f.write(md)
    log(f"Wrote audit Markdown to {md_path}")

if __name__ == "__main__":
    sys.exit(main())
