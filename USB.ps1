$DRIVE= Read-Host -Prompt "Enter Mounted Drive Letter"
$PATH = $DRIVE + '\Users' 
$USER_DIR = Get-ChildItem -Path $PATH -Filter NTUSER.DAT -Recurse -Depth 1 -Name -ErrorAction SilentlyContinue -Force
Get-ForensicRegistryKey -HivePath $SYSTEM -Key ControlSet001\Enum\USBSTOR | Format-Table Name
Get-ForensicRegistryValue -HivePath $SYSTEM -Key MountedDevices | Format-Table Name
Foreach($FILE in $USER_DIR)
{ 
   If ($FILE -ne "Default\NTUSER.DAT") {
      $USER_REG = $PATH + '\' + $FILE
      Write-Host $USER_REG
      Get-ForensicRegistryKey -HivePath $USER_REG -Key SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2 | Sort-Object WriteTime | Format-Table Name, WriteTime
   } 
}
Get-ForensicRegistryKey -HivePath $SYSTEM -Key ControlSet001\Enum\USB | Sort-Object WriteTime | Format-Table Name, WriteTime
