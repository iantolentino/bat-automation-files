@echo off
echo Generating battery report...
powercfg /batteryreport /output "batteryreport.html"
echo Battery report saved as batteryreport.html
echo Opening report...
start batteryreport.html
pause