write-host "`n"
Write-Host "This script collects autoruns"

$DRIVE= Read-Host -Prompt "Enter Mounted Drive Letter"
$PROFILE_PATH = $DRIVE + '\Users' 
$SYSTEM_REG = $DRIVE + '\Windows\System32\Config\SYSTEM'

Write-Host "Get autoruns from the SOFTWARE Hive"

Get-ForensicRunKey -HivePath G:\windows\System32\config\SOFTWARE | format-list

Write-Host "Get autoruns from NTUSER.DAT"
write-host "`n"
$USER_DIR = Get-ChildItem -Path $PATH -Filter NTUSER.DAT -Recurse -Depth 1 -Name -ErrorAction SilentlyContinue -Force
Foreach($FILE in $USER_DIR)
{ 
   If ($FILE -ne "Default\NTUSER.DAT") {
      $USER_REG = $PROFILE_PATH + '\' + $FILE
      Write-Host $USER_REG
      Get-ForensicRunKey -HivePath $USER_REG | Format-List
   } 
}