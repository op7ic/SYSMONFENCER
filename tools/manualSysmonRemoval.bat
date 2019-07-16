@echo off
echo [+] Detecting OS processor type
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto 64BIT
echo [+] X86 present. Removing X86 Sysmon
start "" C:\SYSMONx730185\sysmon.exe -accepteula -u
start "" schtasks /delete /tn KILLMON /F 
start "" sc qc SYSMC186 > SYSService-%computername%.txt
goto END
:64BIT
echo [+] X64 present. Removing X64 Sysmon
start "" C:\SYSMONx730185\sysmon64.exe -accepteula -u
start "" schtasks /delete /tn KILLMON /F 
start "" sc qc SYSMC164 > SYSService-%computername%.txt
:END
echo [+] Sysmon Successfully Removed!
exit