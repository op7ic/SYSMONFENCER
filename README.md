# Overview
This is a simple PowerShell script which will attempd to deploy Sysmon across every domain-connected system. The objective of this script is to be able to deploy, run and collect Sysmoin monitor log as part of Threat Hunting activity where other telemetry collection methods are not available and or using other deployment methods might be difficult.  

# Running

Run ```SYSMONFENCER.ps1``` as domain administrator on domain connected system. Deployment scripts and Sysmon installation files will be uploaded from ```tools/``` directory. **You need to download Sysmon.exe, Sysmon64.exe, Psexec.exe, PSexec64.exe from sysinternals website and place them in "tools" directory if the script will fail to download these files.**

From command line it should be run as follows: 
```powershell.exe -nop -exec bypass .\SYSMONFENCER.ps1```

# Help

```
-=[ SYSMONFENCER v0.2 ]=-
        by op7ic

Usage: powershell .\SYSMONFENCER.ps1 [options]

Options:
  -remove    Removes SYSMON across the domain
  -collect   Collects sysmon evtx files and stores them in output directory
  -help      Show this help menu
```

# Workflow

+------------+       +-----------+
|            |       |           |
|  Threat    +------>+  Deploy   |
|  Hunt      |       |  Sysmon   |
+------------+       +-----+-----+
                           |
                           |
                     +-----v-----+
                     |           |
                     |  Collect  +<------+
                     |  Logs     |       |Repeat
                     +-----+-----+-------+
                           |
                           |
                     +-----v-----+
                     |           |
                     |  Remove   |
                     |  Sysmon   |
                     +-----------+


# Process
The script will perform following actions:

* Attempt to download Sysmon and Psexec from live.sysinternals.com
* Enumerate LDAP structure of the current domain and identify any object matching 'computer' filter. This is done using "System.DirectoryServices.DirectorySearcher" method.
* For each identified system, create unique folder in "C$" network share, copy sysmon config and sysmon installer script into this folder and run quiet installation procedure. 
* The script will use WinRM, WMI and PSEXEC to try to execute remote installation of Sysmon. If all three methods fail then no installation will be performed. 
* Auto-removal task is added so that Sysmon is automatically deleted in 3 weeks from the day of installation. 
* If "-remove" flag is passed to the script it will remove Sysmon across the domain in similar fashion it was installed but with "-u" parameter. Scheluded task will also be removed since we don't need to wait for it to finish.
* If "-collect" flag is passed to the script it will simply collect all sysmon logs from reachable systems and store them in "output" directory

# Sources of Inspiration
* https://github.com/ion-storm/sysmon-config
* https://github.com/MHaggis/sysmon-dfir
* https://www.malwarearchaeology.com/logging/
* https://stackoverflow.com/questions/14526660/how-to-know-if-powershell-is-installed-on-remote-workstation
* Sysmon config copied from https://github.com/SwiftOnSecurity/sysmon-config

# TODO
- [ ] Perform hosts checks (i.e. Disk Size etc) before installing Sysmon 
- [ ] Add method to hide sysmon from service.msc
- [ ] Add threading to main procedures
- [ ] Clean up code and make it look prettier
- [ ] Add .NET implementation so its simple point & click


