# Build & Orchestration Scripts

This directory is designated for future **Crave.io cloud compilation helper and utility scripts**.

---

## 🚫 Local Build Restriction Policy

* **No Local Full Builds**: Due to hardware resource constraints (workstation operates with ~8GB RAM and ~256GB SSD storage), automated full Android compilation (`m`, `ninja`, `make`, `mka`) scripts are **intentionally not provided** for local execution.
* Local tasks are strictly limited to:
  * Repository structure and local manifest maintenance.
  * Patch generation and validation.
  * Fastboot / Recovery flashing and hardware debugging over ADB.

---

## ☁️ Planned Crave.io Helper Scripts

Once the Crave.io account and build environment are fully provisioned, this directory will host:

1. **`crave_prepare.sh`**:
   * Synchronizes `local_manifests/enchilada.xml` into the Crave workspace `.repo/local_manifests/`.
   * Injects necessary bring-up patches into the tree prior to compilation.
2. **`crave_build.sh`**:
   * Triggers remote `crave run` builds with proper target parameters (e.g., `lunch avium_enchilada-userdebug` or `mka bacon`).
3. **`fetch_artifacts.sh`**:
   * Automates the retrieval of completed ROM `.zip`, `boot.img`, and build logs from the Crave build output directory.
