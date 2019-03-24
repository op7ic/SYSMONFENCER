<#
VERSION      DATE          AUTHOR
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
#>

# Run commands against remote system using WMI or Invoke-Command method. Ugly block of code
function runcmdRemove ($SYSTEM){
# Simple test to see if invoke-command works
try{
$invokePSCMD = Invoke-Command -ErrorVariable invokeError -ComputerName $SYSTEM -ScriptBlock {1+1} 2>$null

if ($invokePSCMD -ne "2"){
  Write-Output "[+] Invoke-Command is not allowed against $SYSTEM, attempting WMI trigger"
  $wmicCMD = wmic /node:$SYSTEM process call create "C:\SYSMONx730185\manualSysmonRemoval.bat"
  if ($wmicCMD -like "*successful*"){
    write-output "[+] WMIC execution was successful against $SYSTEM"
  }else{
    # WMI failed, we can try PSEXEC instead
    Write-Output "[+] WMI is not allowed against $SYSTEM, attempting psexec trigger"
	.\tools\Psexec.exe -accepteula \\$SYSTEM -s -i -d "C:\SYSMONx730185\manualSysmonRemoval.bat"
  }
}else{ #Invoke-Command can be used
  Invoke-Command -ComputerName $SYSTEM -ScriptBlock {C:\SYSMONx730185\manualSysmonRemoval.bat}
  }
}catch{}
}# EOF

# Run commands against remote system using WMI or Invoke-Command method. Ugly block of code
function runcmdInstall ($SYSTEM){
try{
# Simple test to see if invoke-command works. Silently
$invokePSCMD = Invoke-Command -ErrorVariable invokeError -ComputerName $SYSTEM -ScriptBlock {1+1} 2>$null

if ($invokePSCMD -ne "2"){
  Write-Output "[+] Invoke-Command is not allowed against $SYSTEM, attempting WMI trigger"
  $wmicCMD = wmic /node:$SYSTEM process call create "C:\SYSMONx730185\manualSysmon.bat"
  if ($wmicCMD -like "*successful*"){
    write-output "[+] WMIC execution was successful against $SYSTEM"
  }else{
    # WMI failed, we can try SCHTASKS instead
    Write-Output "[+] WMI is not allowed against $SYSTEM, attempting psexec trigger"
	.\tools\Psexec.exe -accepteula \\$SYSTEM -s -i -d "C:\SYSMONx730185\manualSysmon.bat"
  }
}else{ #Invoke-Command can be used
  Invoke-Command -ComputerName $SYSTEM -ScriptBlock {C:\SYSMONx730185\manualSysmon.bat}
  }
}catch{}
}# EOF

function help(){
Write-Host @"
Usage: powershell .\SYSMONFENCER.ps1 [options]

Options:
  -remove    Removes SYSMON across the domain
  -help      Show this help menu
"@
}

function deploySYSMONGLOBAL($remove){


write-host "-=[ SYSMONFENCER v0.1 ]=-"
write-host "      by op7ic        "

$toolsReq = @('Sysmon.exe','Sysmon64.exe','Psexec.exe','Psexec64.exe')
for ($i=0; $i -lt $toolsReq.length; $i++) {
	$location = join-path ".\tools" $toolsReq[$i]
	if(!(test-path $location)) {
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	$url = "https://live.sysinternals.com/"+$toolsReq[$i]
	try{
	 $req = Invoke-WebRequest -Uri $url -OutFile "$autorunsPath" -ErrorAction:Stop -TimeoutSec 10
	 }catch {
	 Write-Host @"
	 [!] Tool are missing and unable to download. Please download following and place it in "tools" folder
	 
	     https://live.sysinternals.com/Sysmon.exe
     https://live.sysinternals.com/Sysmon64.exe
     https://live.sysinternals.com/Psexec.exe
     https://live.sysinternals.com/Psexec64.exe
	 [!] Exiting
"@
	exit
	 }
	}else{
	Write-Output "[+] Tools located in tools directory. Continue"
	}
}


$strFilter = "computer";
$objDomain = New-Object System.DirectoryServices.DirectoryEntry
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.SearchScope = "Subtree"
$objSearcher.PageSize = 9999999
$objSearcher.Filter = "(objectCategory=$strFilter)";
$colResults = $objSearcher.FindAll()
$deployerRandomName = "SYSMONx730185"# this gets hardcoded into many parts of this script

foreach ($i in $colResults)
{
        $objComputer = $i.GetDirectoryEntry()
        $remoteBOX = $objComputer.Name
         
        #Step 1 - Create remote folder in C$ which we can use for deployment: 
        $folerLocation = "\\$remoteBOX\`C$\$deployerRandomName"
        Write-Output "[+] Creating Folder For Deployment : $folerLocation"
        #mkdir $folerLocation | out-null
		new-item $folerLocation -ItemType directory | out-null
		#Step 2 - Deploy binaries to specified (hardcoded folder) on each host: 
        Write-Output "[+] Deploing sysmon installation binaries to : $remoteBOX"
		if ($remove -eq $true){
		try{
		 Copy-Item .\tools\Sysmon.exe $folerLocation -Force -ErrorAction SilentlyContinue 
		 Copy-Item .\tools\Sysmon64.exe $folerLocation -Force -ErrorAction SilentlyContinue 
		 Copy-Item .\tools\manualSysmonRemoval.bat $folerLocation -Force -ErrorAction SilentlyContinue 
		# Step 3 - execute commands to initialize sysmon removal
		 runcmdRemove($remoteBOX)
		}catch{
		Write-Output "[-] Unable to remove binaries to : $remoteBOX, perform removal manually" 
		}
		
		}elseif ($remove -eq $false){
		try{
		  Copy-Item .\tools\Sysmon.exe $folerLocation -Force -ErrorAction SilentlyContinue 
		  Copy-Item .\tools\Sysmon64.exe $folerLocation -Force -ErrorAction SilentlyContinue 
		  Copy-Item .\tools\sysmonconfig-export.xml $folerLocation -Force -ErrorAction SilentlyContinue 
		  Copy-Item .\tools\manualSysmon.bat $folerLocation -Force -ErrorAction SilentlyContinue 
		  # Step 3 - execute commands to initialize sysmon installation
		  runcmdInstall($remoteBOX)
		}catch{
		Write-Output "[-] Unable to deploy binaries to : $remoteBOX" 
		}
		}
		#Final step - remove folder from each host (SYSMON runs in background). Will reupload data to remove sysmon and use -u command
		sleep 10
		Remove-Item $folerLocation -force -recurse -ErrorAction SilentlyContinue 
}

}

if($args[0] -eq "-remove"){
Write-Output "[!] Option selected: SYSMON REMOVAL" 
deploySYSMONGLOBAL($true)
}elseif($args[0] -eq "-help"){
help
}else{
Write-Output "[!] Option selected: SYSMON INSTALLATION" 
deploySYSMONGLOBAL($false)
}

