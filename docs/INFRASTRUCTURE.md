# Remote Build Infrastructure & Pipeline Tracking

This document tracks all candidate remote high-performance build environments evaluated and provisioned for executing the full AOSP/AviumUI Android 16 QPR2 compilation for the OnePlus 6 (`enchilada`).

---

## ☁️ Candidate Build Pathways

| # | Provider / Service | Tracked Status | Specs / Capacity | Primary Use Case & Notes |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **Crave.io** | `Pending` | Remote on-demand high-concurrency cloud builders | Direct interactive builds via `crave run` CLI; account authorization pending. |
| **2** | **ROM-builders** | `Pending Whitelist Merge` | Cirrus CI Runner (24 vCPU / 120GB RAM / NVMe) | Automated PR-based CI builds; tracked via upstream PR [`ROM-builders/temporary#25789`](https://github.com/ROM-builders/temporary/pull/25789). |
| **3** | **OSUOSL** | `Hosting Request Submitted` | Open Source Lab dedicated VM / compute cluster | Long-term non-profit OSS hosting & build automation. |
| **4** | **Latchkey OSS** | `Application Submitted` | Community developer compute grant | Free build tier for open-source mobile ROM bring-ups. |
| **5** | **Namespace** | `Trial Active` | Tier M: 8 vCPU / 16GB RAM / 300GB SSD *(Request for Tier L pending)* | Remote containerized build orchestration; currently testing container sync performance. |

---

## 🔒 Security & Credential Policy

* **Zero Secret Storage**: No passwords, personal access tokens (PAT), SSH private keys, API secrets, or Cloud authentication tokens are stored in this repository.
* **Environment-Driven Configuration**: All runners must inject credentials securely at runtime via external CI secret vaults or non-committed local environment files (e.g. `crave.env` ignored in `.gitignore`).
