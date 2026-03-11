# Smart Windows 10 Optimizer

A lightweight Windows optimization script designed to improve performance on low-end and mid-range systems by performing automated maintenance, service tuning, and system diagnostics.

This tool is implemented as a **Batch script (.bat)** and requires **no external dependencies**.

---

# Features

## 1. Automatic Administrator Elevation

The script automatically checks if it is running with administrative privileges.
If not, it will relaunch itself with **Administrator permissions**.

This ensures system repair commands and service configurations run correctly.

---

## 2. RAM Detection

The script detects the system's installed memory and applies different optimization profiles.

Example logic:

| RAM       | Optimization Profile    |
| --------- | ----------------------- |
| ≤ 4GB     | Aggressive optimization |
| 5GB – 8GB | Moderate optimization   |
| > 8GB     | Light optimization      |

This prevents unnecessary service disabling on powerful systems.

---

## 3. Storage Detection (SSD vs HDD)

The script checks the system drive type and adjusts performance tuning.

| Storage | Optimization                         |
| ------- | ------------------------------------ |
| HDD     | Disable SysMain to reduce disk usage |
| SSD     | Keep performance-related services    |

This helps reduce **100% disk usage**, which commonly occurs on HDD systems.

---

# Optimization Tasks Performed

The script performs several maintenance and optimization operations.

### Service Optimization

Disables or adjusts services known to cause performance issues:

* SysMain (Superfetch)
* Windows Search
* Diagnostic Tracking
* Windows Error Reporting

Service changes depend on detected RAM and storage type.

---

### Temporary File Cleanup

Deletes unnecessary system files:

* User TEMP folder
* Windows TEMP folder
* Prefetch cache

This helps reclaim disk space and remove corrupted cache files.

---

### Windows Update Cache Reset

Resets the Windows Update components:

* Stops update services
* Clears SoftwareDistribution folder
* Restarts update services

This resolves common Windows Update errors.

---

### Network Stack Reset

Performs basic network troubleshooting:

* Flush DNS cache
* Reset Winsock
* Reset TCP/IP stack

Useful for fixing network-related issues.

---

### Power Plan Optimization

Switches the system to the **High Performance** power plan to avoid CPU throttling.

---

### Background App Control

Disables background application execution that may consume system resources.

---

### Startup Program Analysis

Generates a report listing all startup programs:

startup_report.txt

This allows users to manually review programs that slow system boot.

---

### System File Integrity Check

Runs:

sfc /scannow

This command scans and repairs corrupted Windows system files.

---

### Disk Health Check

Performs a disk scan:

chkdsk /scan

This checks the filesystem for errors without requiring a reboot.

---

# Output Report

After completion, the script prints a summary:

Example:

Successful Tasks : 10
Failed Tasks : 0

Additional system information is also shown:

* Detected RAM
* Storage type (SSD / HDD)

---

# Requirements

* Windows 10
* Administrator privileges
* Command Prompt environment

No additional software is required.

---

# How to Use

1. Download the script.

2. Save it as:

smart_windows_optimizer.bat

3. Run it normally.

The script will automatically request **Administrator permissions**.

4. Wait for the optimization process to complete.

5. Restart the computer for best results.

---

# Recommended Usage

This script is useful for:

* Slow laptops
* Systems with 4GB–8GB RAM
* HDD-based systems experiencing 100% disk usage
* General Windows maintenance
* IT troubleshooting

---

# Safety Notes

The script modifies system services and clears system caches.

While safe for most environments, it is recommended to:

* Create a system restore point before running
* Review startup programs manually
* Avoid running during critical operations

---

# Known Limitations

* Some commands rely on WMIC, which is deprecated in newer Windows builds.
* Startup programs are only **reported**, not automatically disabled.
* Full disk repair may still require a reboot depending on detected issues.

---

# Future Improvements

Possible enhancements:

* Automatic startup program disabling
* CPU usage diagnostics
* Windows bloatware removal
* SSD/HDD performance benchmarking
* Log file generation
* GUI interface (PowerShell or Python)

---

# Author

Windows Optimization Toolkit

Built for system administrators, developers, and IT support professionals who need a quick maintenance tool without installing additional software.

---

# License

Free to use for educational, personal, and internal IT maintenance purposes.
