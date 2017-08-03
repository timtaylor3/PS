Write-Host "This script collects all of the registry data required for USB Insertion analsyis"

$DRIVE= Read-Host -Prompt "Enter Mounted Drive Letter"
$PROFILE_PATH = $DRIVE + '\Users' 
$SYSTEM_REG = $DRIVE + '\Windows\System32\Config\SYSTEM'

Write-Host "Get USBSTOR info"
Get-ForensicRegistryKey -HivePath $SYSTEM_REG -Key ControlSet001\Enum\USBSTOR | Format-Table Name

Write-Host "Get MountedDevices info"
Get-ForensicRegistryValue -HivePath $SYSTEM_REG -Key MountedDevices | Format-Table Name

Write-Host "Get NTUSER.DAT info"
$USER_DIR = Get-ChildItem -Path $PATH -Filter NTUSER.DAT -Recurse -Depth 1 -Name -ErrorAction SilentlyContinue -Force
Foreach($FILE in $USER_DIR)
{ 
   If ($FILE -ne "Default\NTUSER.DAT") {
      $USER_REG = $PROFILE_PATH + '\' + $FILE
      Write-Host $USER_REG
      Get-ForensicRegistryKey -HivePath $USER_REG -Key SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2 | Sort-Object WriteTime | Format-Table Name, WriteTime
   } 
}
Write-Host "Get Enum\USB info"
Get-ForensicRegistryKey -HivePath $SYSTEM_REG -Key ControlSet001\Enum\USB | Sort-Object WriteTime | Format-Table Name, WriteTime
