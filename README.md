# Windows & Development Automation Scripts Collection

A comprehensive collection of batch and PowerShell scripts for Windows optimization, development environment setup, and system maintenance.

---

## Quick Start

| **I need to...** | **Use this file** |
|-----------------|-------------------|
| Set up a Python/Django project | `create-django-project.bat` |
| Set up a FastAPI project | `create-fastapi-project.bat` |
| Set up a Flask project | `create-flask-project.bat` |
| Fix Windows Update issues | `fix-driver-conflict.bat` |
| Optimize Windows performance | `win10-optimizer.bat` |
| Check server connectivity | `Run-Check-Servers.bat` |
| Install Lenovo Vantage | `installVantage.bat` |

---

## Contents

### Python Development Scripts

| Script | Description | Requirements |
|--------|-------------|--------------|
| `create-django-project.bat` | Creates a complete Django project with venv, .env config (MySQL/PostgreSQL), and core app structure | Python installed |
| `create-fastapi-project.bat` | Basic FastAPI project structure with database config | Python installed |
| `create-fastapi-fullstack.bat` | Full-stack FastAPI project with backend (FastAPI) + frontend folders, venv, and run script | Python installed |
| `create-flask-project.bat` | Flask app with Blueprint structure, templates, static folders, and .env config | Python installed |
| `python-environment-setup.bat` | Activates venv, installs requirements, runs app.py | `requirements.txt`, `app.py` |
| `reinstall-python.bat` | ** Admin required** - Removes old Python, downloads & installs Python 3.12.2 system-wide | Internet, Admin rights |

### Windows System Scripts

| Script | Description | Requirements |
|--------|-------------|--------------|
| `win10-optimizer.bat` | ** Admin required** - 10-step optimization: services, temp cleanup, network reset, power plan, SFC scan | Admin rights |
| `fix-driver-conflict.bat` | ** Admin required** - Full Windows Update repair + driver conflict fix (sets Safe Boot) | Admin rights |
| `winsoftupdate.bat` | ** Admin required** - Fixes Software Center (SCCM) + Windows Update issues | Admin rights |
| `DeleteRegistryPol.bat` | Deletes Registry.pol and runs gpupdate /force | Admin rights |
| `battery_report.bat` | Generates Windows battery health report (HTML) | Windows |

### Lenovo-Specific Scripts

| Script | Description | Requirements |
|--------|-------------|--------------|
| `installVantage.bat` | ** Admin required** - Installs Lenovo Commercial Vantage (requires `VantageInstaller.exe` in same folder) | Admin rights, installer file |
| `ReinstallLenovoVantage.bat` | ** Admin required** - Cleanup + reinstall Vantage from specific folder path | Admin rights, specific folder structure |
| `uninstallvantage.ps1` | ** Admin required** - Complete removal of ALL Lenovo Vantage components, services, registry keys, and residuals | PowerShell, Admin rights |

### Network & Server Scripts

| Script | Description | Requirements |
|--------|-------------|--------------|
| `Run-Check-Servers.bat` | Launcher for `Check-Servers.ps1` | PowerShell |
| `Check-Servers.ps1` | Server connectivity checker (Ping + TCP ports: 3389,445,80,443,22). Outputs: Console + Dark HTML report + CSV | PowerShell |
| `Check-Servers-old.ps1` | Older version - console-only server check | PowerShell |

---

## Detailed Usage Guides

### Python Project Generation

#### Django Project
```batch
# Run as Administrator (for global installs) or normal user
create-django-project.bat

# Enter project name when prompted
# Creates: venv, requirements.txt, .env (MySQL/PostgreSQL), core app
```

#### FastAPI Fullstack
```batch
create-fastapi-fullstack.bat

# Creates:
# backend/    - FastAPI app with SQLAlchemy, routers
# frontend/   - HTML/CSS/JS structure
# run_backend.bat - One-click server starter
```

#### Flask Project
```batch
create-flask-project.bat

# Creates app with Blueprint routing, templates/, static/
# Run with: call venv\Scripts\activate && python run.py
```

### Server Connectivity Check

```batch
# 1. Edit Check-Servers.ps1 - modify $Servers and $Ports arrays
# 2. Run:
Run-Check-Servers.bat

# Outputs:
# - Colored console summary
# - Dark HTML report (auto-opens in browser)
# - CSV file for Excel analysis
```

### Windows Optimization

```batch
# Run as Administrator
win10-optimizer.bat

# Performs:
# 1. Service optimization (based on RAM)
# 2. Temp file cleanup
# 3. Windows Update reset
# 4. Prefetch cleanup
# 5. Network stack reset
# 6. High Performance power plan
# 7. Background apps disabled
# 8. Startup report (startup_report.txt)
# 9. SFC /scannow
# 10. CHKDSK /scan
```

### Complete Lenovo Vantage Cleanup

```powershell
# Run PowerShell as Administrator
.\uninstallvantage.ps1

# Removes:
# - All Vantage UWP packages (all users)
# - Provisioned packages
# - Vantage Service (MSI/Inno)
# - System Interface Foundation
# - All user profile AppData leftovers
# - Registry keys (HKLM/HKCU)
# - Scheduled tasks
# - WMI consumers/filters
# - ProgramData, ProgramFiles folders
```

---

## Important Notes

### Administrator Rights Required For:
- `reinstall-python.bat`
- `win10-optimizer.bat`
- `fix-driver-conflict.bat`
- `winsoftupdate.bat`
- `DeleteRegistryPol.bat`
- `installVantage.bat`
- `ReinstallLenovoVantage.bat`
- `uninstallvantage.ps1`

### Before Running System Scripts:
1. **Save your work** - Some scripts require restarts
2. **Create a restore point** - Especially before `win10-optimizer.bat`
3. **Run as Administrator** - Right-click → Run as Administrator
4. **Read the output** - Scripts provide status messages

### `fix-driver-conflict.bat` - Special Note:
This script sets **Safe Boot** mode. After running:
1. Restart PC (boots into Safe Mode)
2. Install Windows Updates
3. Run: `bcdedit /deletevalue {current} safeboot`
4. Restart again to normal mode

---

## Script Output Locations

| Script | Output File |
|--------|-------------|
| `battery_report.bat` | `batteryreport.html` (current folder) |
| `Check-Servers.ps1` | `Connectivity_Report_YYYYMMDD_HHMMSS.html` + `.csv` |
| `win10-optimizer.bat` | `startup_report.txt` |
| `uninstallvantage.ps1` | `C:\ProgramData\LenovoVantage_Cleanup.log` |

---

## Troubleshooting

### "Access Denied" or "Run as Administrator"
- Right-click the `.bat` file → **Run as Administrator**
- Or open CMD/PowerShell as Admin and run the script

### PowerShell Execution Policy Error
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### Python Scripts Fail
- Ensure Python is in PATH: `python --version`
- Run `reinstall-python.bat` as Admin to fix Python installation

### "File not found" errors
- Scripts expect certain file structures (e.g., `VantageInstaller.exe` for `installVantage.bat`)
- Check script comments for required files/folders

---

## File Dependencies

| Main Script | Requires |
|-------------|----------|
| `installVantage.bat` | `VantageInstaller.exe` (in same folder) |
| `ReinstallLenovoVantage.bat` | Specific folder structure: `Desktop\LenovoVantage_4.27.32.0\Discovery_4.27.32.0\` |
| `python-environment-setup.bat` | `requirements.txt`, `app.py` |
| `Run-Check-Servers.bat` | `Check-Servers.ps1` (same folder) |

---

## License

These scripts are provided as-is for educational and productivity purposes. Test in a safe environment before running on production systems.

---

## Contributing

Found a bug or have an improvement? Feel free to modify the scripts to fit your needs. Most scripts include comments explaining each section.

---

**Last Updated:** APRIL 2026
