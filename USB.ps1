$DRIVE= Read-Host -Prompt "Enter Mounted Drive Letter"
$USER_NAME = Read-Host -Prompt "Enter User Name"
$USER_PROFILE = $DRIVE + "\Users\" + $USER_NAME
$SYSTEM = $DRIVE + "\Windows\System32\config\SYSTEM"

Get-ForensicRegistryKey -HivePath $SYSTEM -Key ControlSet001\Enum\USBSTOR | Format-Table Name
Get-ForensicRegistryValue -HivePath $SYSTEM -Key MountedDevices | Format-Table Name
Get-ForensicRegistryKey -HivePath ( $USER_PROFILE + "\NTUSER.DAT" ) -Key SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2 | Sort-Object WriteTime | Format-Table Name, WriteTime
Get-ForensicRegistryKey -HivePath $SYSTEM -Key ControlSet001\Enum\USB | Sort-Object WriteTime | Format-Table Name, WriteTime
