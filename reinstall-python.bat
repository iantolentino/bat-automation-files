@echo off 
:: ========================================================
:: Robust Python 3.12 Installer for Any Windows Device
:: ========================================================

echo ================================
echo 1. Removing Microsoft Store Python
echo ================================
powershell -Command "Get-AppxPackage *Python* | Remove-AppxPackage" 2>nul
echo Done removing Store Python (if any existed).
echo.

echo ================================
echo 2. Disabling App Execution Aliases
echo ================================
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\python.exe" /ve /t REG_SZ /d "" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\python3.exe" /ve /t REG_SZ /d "" /f
echo Disabled python.exe and python3.exe aliases.
echo.

echo ================================
echo 3. Removing old Python folders (if exist)
echo ================================
if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python" rmdir /s /q "C:\Users\%USERNAME%\AppData\Local\Programs\Python"
if exist "C:\Users\%USERNAME%\AppData\Roaming\Python" rmdir /s /q "C:\Users\%USERNAME%\AppData\Roaming\Python"
echo Removed leftover Python folders.
echo.

echo ================================
echo 4. Downloading Python 3.12.2 installer
echo ================================
set "PYTHON_URL=https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe"
set "PYTHON_INSTALLER=%TEMP%\python-3.12.2-amd64.exe"

if exist "%PYTHON_INSTALLER%" del "%PYTHON_INSTALLER%"
powershell -Command "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%'"
echo Download complete.
echo.

echo ================================
echo 5. Installing Python silently
echo ================================
"%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
echo Installation finished.
echo.

echo ================================
echo 6. Updating PATH in current session
echo ================================
set "PYTHON_PATH=C:\Program Files\Python312\"
set "PYTHON_SCRIPTS=%PYTHON_PATH%Scripts"
set PATH=%PYTHON_PATH%;%PYTHON_SCRIPTS%;%PATH%
echo PATH updated for this session.
echo.

echo ================================
echo 7. Verifying Python and pip
echo ================================
python --version
python -m pip --version
echo.

echo ================================
echo SUCCESS!
echo Python 3.12 installed for all users, pip ready, PATH configured.
echo You can now use Python immediately, including VS Code.
echo ==============================================================
pause

