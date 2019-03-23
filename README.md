# Overview
This is a simple PowerShell script which will enumerate the domain, deploy and run Sysmon monitor across every reachable system. The objective of this script is to be able to deploy and run Sysmon monitor for a number of days as part of Threat Hunting activity where other telemetry collection methods are not available.  

# Running

Run ```SYSMONFENCER.ps1``` as domain administrator on domain connected system. Deployment scripts and copy of Sysmon will be uploaded from ```tools/``` directory.

# Help

```
-=[ SYSMONFENCER v0.1 ]=-
        by op7ic

Usage: powershell .\SYSMONFENCER.ps1 [options]

Options:
  -remove    Removes SYSMON across the domain
```

# Process
The script will perform followin actions:

* Enumerate LDAP structure of the current domain and identify any object matching 'computer' filter. This is done using "System.DirectoryServices.DirectoryEntry" and "System.DirectoryServices.DirectorySearcher" methods.
* For each identified system, create unique folder in "C:" parition, copy sysmon config and sysmon installer into this folder and run quiet installation procedure. 
* Auto-removal task is added so that Sysmon is authomatically deleted in 3 weeks from the day of installation. 
* If "-remove" flag is passed to the script it will remove Sysmon across the domain in similar fashion it was installed but with "-u" parameter.

# Sources of Inspiration
* https://github.com/ion-storm/sysmon-config
* https://github.com/MHaggis/sysmon-dfir
* https://www.malwarearchaeology.com/logging/
* https://stackoverflow.com/questions/14526660/how-to-know-if-powershell-is-installed-on-remote-workstation

# TODO
- [ ] Output to files (json)
- [ ] Perform hosts checks (i.e. Disk Size etc) before installing Sysmon 
- [ ] The deployer script to also hide sysmon from service.msc
- [ ] Add threading to upload procedure
 


