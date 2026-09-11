# Remote Build Infrastructure & Pipeline Tracking

This document tracks all candidate remote high-performance build environments evaluated and provisioned for executing the full AOSP/AviumUI Android 16 QPR2 compilation for the OnePlus 6 (`enchilada`).

---

## ☁️ Candidate Build Pathways

| # | Provider / Service | Tracked Status | Specs / Capacity | Primary Use Case & Notes |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **Namespace (Primary)** | `Active & Verified` | **32 vCPU AMD EPYC Zen 4 / 62 GiB RAM**<br>Root NVMe: 284 GiB available (1.8 GB/s write)<br>Cache Volume: 121 GiB persistent ext4 (1.1 GB/s write) | **Primary production build platform** via GitHub Actions runner label `namespace-profile-avium-run15`. Multi-stage gated build (`nothing` -> `bootimage` -> `bacon`). |
| **2** | **HexDroid** | `Standby` | HexDroid cloud builder | Secondary fallback configuration maintained in `.hexdroid/avium-enchilada.yaml`. |
| **3** | **Crave.io** | `Historical / Auxiliary` | Remote on-demand high-concurrency cloud builders | Interactive build history preserved in `docs/CRAVE_BOOTSTRAP.md`. |
| **4** | **ROM-builders** | `Pending Whitelist Merge` | Cirrus CI Runner (24 vCPU / 120GB RAM / NVMe) | Automated PR-based CI builds; tracked via upstream PR [`ROM-builders/temporary#25789`](https://github.com/ROM-builders/temporary/pull/25789). |
| **5** | **OSUOSL** | `Hosting Request Submitted` | Open Source Lab dedicated VM / compute cluster | Long-term non-profit OSS hosting & build automation. |
| **6** | **Latchkey OSS** | `Application Submitted` | Community developer compute grant | Free build tier for open-source mobile ROM bring-ups. |

---

## 🔒 Security & Credential Policy

* **Zero Secret Storage**: No passwords, personal access tokens (PAT), SSH private keys, API secrets, or Cloud authentication tokens are stored in this repository.
* **Environment-Driven Configuration**: All runners must inject credentials securely at runtime via external CI secret vaults or non-committed local environment files (e.g. `crave.env` ignored in `.gitignore`).
