$DRIVE= Read-Host -Prompt "Enter Mounted Drive Letter"
$USER_NAME = Read-Host -Prompt "Enter User Name"
$USER_PROFILE = $DRIVE + "\Users\" + $USER_NAME
$SYSTEM = $DRIVE + "\Windows\System32\config\SYSTEM"
$SOFTWARE = $DRIVE + "\Windows\System32\config\SOFTWARE"
$SECURITY = $DRIVE + "\Windows\System32\config\SECURITY"
$SAM = $DRIVE + "\Windows\System32\config\SAM"
$SYSTEM_ROOT = $DRIVE + "\Windows"
$AMCACHE = $DRIVE + "\Windows\AppCompat\Programs\Amcache.hve"

Get-ForensicAmcache -HivePath $AMCACHE | Format-Table 
Get-ForensicAttrDef -VolumeName $DRIVE
Get-ForensicExplorerTypedPath -VolumeName $DRIVE
Get-ForensicEventLog -Path ( $SYSTEM_ROOT + "\system32\winevt\logs\Security.evtx") | Format-Table
Get-ForensicOfficeFileMru -VolumeName $DRIVE | Format-Table
Get-ForensicPrefetch -VolumeName $Drive | Format-Table
Get-ForensicRegistryKey -HivePath $SAM -Recurse | Format-Table
Get-ForensicRunKey -VolumeName $DRIVE | Format-Table
Get-ForensicRunMRU -VolumeName $DRIVE | Format-Table
Get-ForensicScheduledJob -Volume $DRIVE
Get-ForensicShellLink -VolumeName $DRIVE 
Get-ForensicShimcache -HivePath $SYSTEM | Format-Table
Get-ForensicTimezone -HivePath $SYSTEM | Format-Table
Get-ForensicUserAssist -VolumeName $DRIVE | Format-Table
Get-ForensicVolumeBootRecord -VolumeName $DRIVE | Format-Table
Get-ForensicVolumeInformation -VolumeName $DRIVE | Format-Table
Get-ForensicVolumeName -VolumeName $DRIVE
Get-ForensicWindowsSearchHistory -VolumeName $DRIVE
Get-ForensicWindowsSearchHistory -HivePath ( $USER_PROFILE + "\NTUSER.DAT" ) | Format-Table 
Get-ForensicRegistryValue -HivePath $SYSTEM -Key ControlSet001\Control\ComputerName\ComputerName | Format-Table
Get-ForensicRegistryKey -HivePath $SYSTEM -Key ControlSet001\Enum\USBSTOR | Format-Table
Get-ForensicRegistryValue -HivePath $SYSTEM -Key MountedDevices | Format-Table
Get-ForensicRegistryKey -HivePath ( $USER_PROFILE + "\NTUSER.DAT" ) -Key SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2 | Format-Table
Get-ForensicRegistryKey -HivePath $SYSTEM -Key ControlSet001\Enum\USB | Format-Table