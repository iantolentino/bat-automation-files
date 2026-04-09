@echo off
title Fix Software Center and Windows Update
color 1F

echo ====================================================
echo   Fixing Software Center and Windows Update Issues
echo ====================================================
echo.
echo This script must be run as ADMINISTRATOR.
echo.

pause

echo.
echo [1/7] Stopping Windows Update related services...
net stop wuauserv /y
net stop bits /y
net stop cryptsvc /y
net stop ccmexec /y

echo.
echo [2/7] Clearing Windows Update cache...
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
ren C:\Windows\System32\catroot2 catroot2.old

echo.
echo [3/7] Resetting BITS and Windows Update services...
sc config wuauserv start= auto
sc config bits start= delayed-auto
sc config cryptsvc start= auto

echo.
echo [4/7] Restarting services...
net start cryptsvc
net start bits
net start wuauserv
net start ccmexec

echo.
echo [5/7] Repairing SCCM Client (Software Center)...
ccmrepair

echo.
echo [6/7] Triggering Software Center policy sync...
wmic /namespace:\\root\ccm path sms_client call TriggerSchedule "{00000000-0000-0000-0000-000000000021}"
wmic /namespace:\\root\ccm path sms_client call TriggerSchedule "{00000000-0000-0000-0000-000000000022}"

echo.
echo [7/7] Triggering Windows Update detection...
usoclient StartScan
usoclient StartDownload
usoclient StartInstall

echo.
echo ====================================================
echo   Process completed successfully.
echo ====================================================
echo.
echo Please RESTART the laptop after this script finishes.
echo Then open Software Center and try updating again.
echo.

pause
exit