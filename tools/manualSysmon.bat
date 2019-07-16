@echo off
echo [+] Detecting OS processor type
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto 64BIT
echo [+] X86 present. Installing X86 Sysmon
SET SYSMONDIR=C:\windows\sysmon64.exe
IF Not EXIST %SYSMONDIR% (
C:\SYSMONx730185\sysmon.exe -n -l -d SYSMC186 -accepteula -i C:\SYSMONx730185\sysmonconfig-export.xml
sc failure SYSMC186 actions= restart/10000/restart/10000// reset= 120
sc qc SYSMC186 > SYSService-%computername%.txt
echo [+] Creating Auto Removal Task Which Will Kill Sysmon After 3 weeks
SchTasks /Create /RU SYSTEM /RL HIGHEST /SC weekly /mo 3 /TN KILLMON /TR "C:\SYSMONx730185\sysmon.exe -u" /F
:: Increase logging space
wevtutil.exe sl Microsoft-Windows-Sysmon/Operational /ms:209715200
echo [+] Sysmon Successfully Installed!
) 
goto END
:64BIT
echo [+] X64 present. Installing X64 Sysmon
SET SYSMONDIR=C:\windows\sysmon.exe
IF Not EXIST %SYSMONDIR% (
C:\SYSMONx730185\sysmon64.exe -n -l -accepteula -d SYSMC164 -i C:\SYSMONx730185\sysmonconfig-export.xml
sc failure SYSMC164 actions= restart/10000/restart/10000// reset= 120
sc qc SYSMC164 > SYSService-%computername%.txt
echo [+] Creating Auto Removal Task Which Will Kill Sysmon After 3 weeks
SchTasks /Create /RU SYSTEM /RL HIGHEST /SC weekly /mo 3 /TN KILLMON /TR "C:\SYSMONx730185\sysmon64.exe -u" /F
:: Increase logging space
wevtutil.exe sl Microsoft-Windows-Sysmon/Operational /ms:209715200
echo [+] Sysmon Successfully Installed!
)
:END
exit