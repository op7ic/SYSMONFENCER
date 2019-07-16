<#
VERSION      DATE          AUTHOR
0.4A      14/07/2019       op7ic
0.2A      23/03/2019       op7ic
0.1A      22/03/2019       op7ic
#> # Revision History


<#
  .SYNOPSIS
    Deploys SYSMON across the domain. WARNING: This script needs to run with Domain Admin privilages
  .EXAMPLE
    SYSMONFENCER.ps1
  .HELP 
    Add -remove parameter to remove installed SYSMON globally
	Add -collect parameter to collect SYSMON logs globally
#>

function help(){
Write-Host @"
Usage: powershell .\SYSMONFENCER.ps1 [options]

Options:
  -remove    Removes SYSMON across the domain
  -collect   Collects SYSMON logs across domain and store in local folder ./output
  -help      Show this help menu
"@
}

function fancyDeploy($serverListArray){

foreach ($remoteServer in $serverListArray){
# control running jobs, max 4 
	$running = @(Get-Job | Where-Object { $_.State -eq 'Running' })
	if ($running.Count -ge 4) {
	    $running | Wait-Job -Any | Out-Null
    }
	Start-Job {
	$timestampStart = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
	Write-Host "[+] Starting Sysmon deployment for $using:remoteServer at $timestampStart"
	#Start new jobs for each system in serverListArray variable but control to max 4 jobs 
	$deployerRandomName = "SYSMONx730185"# this gets hardcoded into many parts of this script
	#Step 1 - Create remote folder in C$ which we can use for deployment: 
    $folerLocation = "\\$using:remoteServer\`C$\$deployerRandomName"
    
    if (Test-Path $folerLocation) {
	Write-Host "[!] Folder $folerLocation already exists. Removing and recreating"
	Remove-Item $folerLocation -Force -Recurse
	new-item $folerLocation -ItemType directory -ErrorAction SilentlyContinue | out-null
    }else{
    new-item $folerLocation -ItemType directory -ErrorAction SilentlyContinue | out-null
    }
	try{
	#Step 2 - Deploy binaries to specified (hardcoded folder) on each host: 
    Write-Host "[+] Deploing sysmon installation binaries to: $using:remoteServer"
    Copy-Item "$PWD\tools\Sysmon.exe" $folerLocation -force -ErrorAction SilentlyContinue 
    Copy-Item "$PWD\tools\Sysmon64.exe" $folerLocation -force -ErrorAction SilentlyContinue 
	Copy-Item "$PWD\tools\sysmonconfig-export.xml" $folerLocation -ErrorAction SilentlyContinue 
	Copy-Item "$PWD\tools\manualSysmon.bat" $folerLocation -force -ErrorAction SilentlyContinue 
	# Step 3 - execute commands to initialize sysmon installation
	# Simple test to see if invoke-command works. Silently
	$invokePSCMD = Invoke-Command -ErrorVariable invokeError -ComputerName $using:remoteServer -ScriptBlock {1+1} 2>$null
	if ($invokePSCMD -ne "2"){
	Write-Host "[+] Invoke-Command is not allowed against $using:remoteServer, attempting WMI trigger"
	$wmicCMD = wmic /node:$using:remoteServer process call create "C:\SYSMONx730185\manualSysmon.bat" 2>&1 
	if ($wmicCMD -like "*successful*"){
    write-Host "[+] WMIC execution was successful against $using:remoteServer"
	}else{
    #WMI failed, we can try PSEXEC instead
    Write-Host "[+] WMI is not allowed against $using:remoteServer, attempting psexec trigger"
	$psExeJob="$PWD\tools\Psexec.exe -accepteula \\$using:remoteServer-s -i -d 'C:\SYSMONx730185\manualSysmon.bat'"
	&"$psExeJob"
	}
	}else{ #Invoke-Command can be used
	Invoke-Command -ComputerName $using:remoteServer -ScriptBlock {C:\SYSMONx730185\manualSysmon.bat}
	}
	}catch{
	Write-Host "[!] Sysmon couldn't be deployed against $using:remoteServer because server is either off or we cannot write to network share"
	}
	$timestampEnd = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
	#Sleeping 3 before we attempd to remove the folder, retry removal 5 times
	For ($i=0; $i -le 5; $i++) {
	if (Test-Path $folerLocation) {
	Remove-Item $folerLocation -Force -Recurse -ErrorAction SilentlyContinue
	sleep 3
	}else{
	break
	}
    }
	Write-Host "[+] Finished Sysmon deployment for $using:remoteServer at $timestampEnd"
	} -InitializationScript ([scriptblock]::Create("Set-Location $PWD")) | Out-Null # EOF JOB
	
}#EOF foreach
# Wait for all jobs to complete and results ready to be received
Wait-Job * | Out-Null
# Process the results
foreach($job in Get-Job)
{
    $result = Receive-Job $job
}
Remove-Job -State Completed
}

function fancyRemoval($serverListArray){
foreach ($remoteServer in $serverListArray){
# control running jobs, max 4 
	$running = @(Get-Job | Where-Object { $_.State -eq 'Running' })
	if ($running.Count -ge 4) {
	    $running | Wait-Job -Any | Out-Null
    }
	Start-Job {
	$timestampStart = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
	Write-Host "[+] Starting Sysmon removal for $using:remoteServer at $timestampStart"
	#Start new jobs for each system in serverListArray variable but control to max 4 jobs 
	$deployerRandomName = "SYSMONx730185"# this gets hardcoded into many parts of this script
	#Step 1 - Create remote folder in C$ which we can use for deployment: 
    $folerLocation = "\\$using:remoteServer\`C$\$deployerRandomName"

    if (Test-Path $folerLocation) {
	Write-Host "[!] Folder $folerLocation already exists. Removing and recreating"
	Remove-Item $folerLocation -Force -Recurse -ErrorAction SilentlyContinue
	new-item $folerLocation -ItemType directory -ErrorAction SilentlyContinue | out-null
    }else{
    new-item $folerLocation -ItemType directory -ErrorAction SilentlyContinue | out-null
    }
	try{
	#Step 2 - Deploy binaries to specified (hardcoded folder) on each host: 
    Write-Host "[+] Deploing sysmon removal binaries to: $using:remoteServer"
    Copy-Item "$PWD\tools\Sysmon.exe" $folerLocation -force -ErrorAction SilentlyContinue 
    Copy-Item "$PWD\tools\Sysmon64.exe" $folerLocation -force -ErrorAction SilentlyContinue 
	Copy-Item "$PWD\tools\manualSysmonRemoval.bat" $folerLocation -force -ErrorAction SilentlyContinue 
	# Step 3 - execute commands to initialize sysmon installation
	# Simple test to see if invoke-command works. Silently
	$invokePSCMD = Invoke-Command -ErrorVariable invokeError -ComputerName $using:remoteServer -ScriptBlock {1+1} 2>$null
	if ($invokePSCMD -ne "2"){
	Write-Host "[+] Invoke-Command is not allowed against $using:remoteServer, attempting WMI trigger"
	$wmicCMD = wmic /node:$using:remoteServer process call create "C:\SYSMONx730185\manualSysmonRemoval.bat" 2>&1 
	if ($wmicCMD -like "*successful*"){
    write-Host "[+] WMIC execution was successful against $using:remoteServer"
	}else{
    #WMI failed, we can try PSEXEC instead
    Write-Host "[+] WMI is not allowed against $using:remoteServer, attempting psexec trigger"
	$psExeJob="$PWD\tools\Psexec.exe -accepteula \\$using:remoteServer-s -i -d 'C:\SYSMONx730185\manualSysmonRemoval.bat'"
	&"$psExeJob"
	}
	}else{ #Invoke-Command can be used
	Invoke-Command -ComputerName $using:remoteServer -ScriptBlock {C:\SYSMONx730185\manualSysmonRemoval.bat}
	}
	}catch{
	Write-Host "[!] Sysmon couldn't be removed from $using:remoteServer because server is either off or we cannot write to network share"
	}
	$timestampEnd = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
	#Sleeping 3 before we attempd to remove the folder, retry removal 5 times
	For ($i=0; $i -le 5; $i++) {
	if (Test-Path $folerLocation) {
	Remove-Item $folerLocation -Force -Recurse -ErrorAction SilentlyContinue
	sleep 3
	}else{
	break
	}
    }
	Write-Host "[+] Finished Sysmon removal for $using:remoteServer at $timestampEnd"
	} -InitializationScript ([scriptblock]::Create("Set-Location $PWD")) | Out-Null # EOF JOB
}#EOF foreach
# Wait for all jobs to complete and results ready to be received
Wait-Job * | Out-Null
# Process the results
foreach($job in Get-Job)
{
    $result = Receive-Job $job
}
Remove-Job -State Completed
}

function fancyCollect($serverListArray){
foreach ($remoteServer in $serverListArray){
# control running jobs, max 4 
	$running = @(Get-Job | Where-Object { $_.State -eq 'Running' })
	if ($running.Count -ge 4) {
	    $running | Wait-Job -Any | Out-Null
    }
	Start-Job {
	$timestampStart = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
	Write-Host "[+] Starting Sysmon log collection for $using:remoteServer at $timestampStart"
	$pathCollectionFolder = "$PWD\output"# this gets hardcoded into many parts of this script
	#Step 1 - Create local folder in the same directory as we run sysmon which we can use for deployment: 
    if([System.IO.File]::Exists($pathCollectionFolder))
	{
		$fileLocation = "\\$using:remoteServer\`C$\Windows\System32\winevt\Logs\Microsoft-Windows-Sysmon%4Operational.evtx"
		$destination = "$pathCollectionFolder\$using:remoteServer-SYSMON.evtx"
		Copy-Item $fileLocation $destination -Force -ErrorAction SilentlyContinue
		if([System.IO.File]::Exists($destination)){
        Write-Host "[+] Sysmon log collected successfully for $using:remoteServer"
        }else{
        Write-Host "[!] Unable to collect Sysmon for $using:remoteServer"
        }
	}else{
	# create folder
	new-item $pathCollectionFolder -ItemType directory -ErrorAction SilentlyContinue | out-null
	$fileLocation = "\\$using:remoteServer\`C$\Windows\System32\winevt\Logs\Microsoft-Windows-Sysmon%4Operational.evtx"
	$destination = "$pathCollectionFolder\$using:remoteServer-SYSMON.evtx"
	Copy-Item $fileLocation $destination -Force -ErrorAction SilentlyContinue
	if([System.IO.File]::Exists($destination)){
		Write-Host "[+] Sysmon log collected successfully for $using:remoteServer"
        }else{
        Write-Host "[!] Unable to collect Sysmon for $using:remoteServer"
        }
	}
	$timestampEnd = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
	Write-Host "[+] Finished Sysmon log collection for $using:remoteServer at $timestampEnd"
	} -InitializationScript ([scriptblock]::Create("Set-Location $PWD")) | Out-Null # EOF JOB
}#EOF foreach
# Wait for all jobs to complete and results ready to be received
Wait-Job * | Out-Null
# Process the results
foreach($job in Get-Job)
{
    $result = Receive-Job $job
}
Remove-Job -State Completed
}

function enumDomainObjects{

write-host "-=[ SYSMONFENCER 0.4A ]=-"
write-host "      by op7ic        "


# Enumerate systems connected to domain
$strFilter = "computer";
$objDomain = New-Object System.DirectoryServices.DirectoryEntry
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.SearchScope = "Subtree"
$objSearcher.PageSize = 9999999
$objSearcher.Filter = "(objectCategory=$strFilter)";
$colResults = $objSearcher.FindAll()

$serverListArray = [System.Collections.ArrayList]@()
foreach ($i in $colResults)
{
        $objComputer = $i.GetDirectoryEntry()
        $remoteBOX = $objComputer.Name
		#Step 1 - enumerate the domain and save host list to array
		$serverListArray.Add($remoteBOX) | out-null
}
return $serverListArray
}#EOF deploySYSMONGLOBAL


$serverListArray = enumDomainObjects

if($args[0] -eq "-remove"){
Write-Output "[!] Option selected: SYSMON REMOVAL" 
write-host "[+] Enumerating domain & removing Sysmon"
fancyRemoval $serverListArray 
}elseif($args[0] -eq "-help"){
help
}elseif($args[0] -eq "-collect") {
Write-Output "[!] Option selected: SYSMON LOG COLLECTION" 
write-host "[+] Enumerating domain & collecting Sysmon logs"
fancyCollect $serverListArray
}else{
Write-Output "[!] Option selected: SYSMON INSTALLATION" 
write-host "[+] Enumerating domain & installing Sysmon across every system"
fancyDeploy $serverListArray
}
