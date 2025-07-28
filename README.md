# 🗂️ User Home Directory (UHD) Management and Automation

## 📋 Overview

This project implements a **semi-automated home folder management system** for Active Directory users in the company infrastructure. It ensures:

- ✅ Secure and centralized storage
- ✅ Quota-controlled data usage
- ✅ Event-driven automation for user folder provisioning and archival

⚠️ **No automatic deletion is performed**. Disabled user data is safely **archived** after an inactivity threshold.

> 🧰 Based on native Windows tools: PowerShell, Task Scheduler, FSRM, Group Policy.

---

## 🔧 System Components

- **Domain Controller (AD)**
  - **iSCSI Initiator**
  - **File Server Role**
  - **Windwos Task Scheduler**
  - **Group Policy Manager**
- **NAS Storage (iSCSI)**

---

## 🔗 Core Components

### 1. 🏠 Home Folder Creation & Archiving

- **Script**: `src/HomeFolderManager.ps1`
- **Functionality**:
  - Creates a personal folder for each user in the `CompanyStaff` group
  - Sets NTFS permissions (Full Control)
  - Archives folder after `X` days if the user is disabled
  - Logs every action to `.log` and `.csv`

#### 🛠 Script Configuration Parameters

| Parameter     | Description                                  | Example Value          |
|---------------|----------------------------------------------|------------------------|
| `$GroupName`  | Security group to manage                     | `CompanyStaff`            |
| `$HomeRoot`   | Root directory for active home folders       | `H:\Home`              |
| `$ArchiveRoot`| Archive location for disabled user folders   | `H:\HomeArchive`       |
| `$LogFile`    | Plain text log output                        | `H:\Logs\HomeFolder.log` |
| `$CsvLog`     | CSV audit log                                | `H:\Logs\HomeFolderAudit.csv` |
| `$DaysToWait` | Days after disablement before archiving      | `150`                  |

---

### 2. 📦 Per-User Quota Enforcement

- Uses **File Server Resource Manager (FSRM)** on the AD server
- Enforces **5 GB quotas** on:
  - Home folders (`H:\Home\`)
  - Archive folders (`H:\HomeArchive\`)
- Templates are **auto-applied** on folder creation or archival

---

### 3. 🔁 Drive Mapping via GPO

- **Group Policy Preference (GPP)** maps:
  - `\\NAS\Home\%username%` → `N:` on user machine
- GPO is item-level targeted to the `CompanyStaff` group
- Prevents exposure to parent directories
- Decoupled from AD profile attributes for flexibility

---

## 🕒 Automation Triggers

The script is designed to run automatically in response to:

| Trigger Type        | Condition                              | Source                 |
|---------------------|-----------------------------------------|------------------------|
| **Event ID `4732`** | User added to a group                   | Security Log           |
| **Event ID `4725`** | User disabled                           | Security Log           |
| **Monthly Schedule**| Last day of each month                  | Task Scheduler         |

> ✅ All conditions run the same script. The logic inside handles create/archive.

---
