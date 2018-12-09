<#
 Extract key artifacts from an image file using Plaso
 Run selected Eric Zimmerman's Tools against the extracted data 
 Download the tools from these locations: 
     https://github.com/log2timeline/plaso/releases
     https://ericzimmerman.github.io/#!index.md 
#>

##############################
# Get User Input
##############################

$top_level = Read-Host -Prompt "Enter Top Level Case Directory"
$image_file = Read-Host -Prompt "Enter the image file to process"

$tools = Join-Path -Path $PSScriptRoot -ChildPath "Tools"
$plaso = Join-Path -Path $PSScriptRoot -ChildPath "Plaso"

$AmcacheParser = Join-Path -Path $tools -ChildPath "AmcacheParser.exe" 
$AppCompatCacheParser = Join-Path -Path $tools -ChildPath "AppCompatCacheParser.exe" 
$JLECmd = Join-Path -Path $tools -ChildPath "JLECmd.exe"
$MFTECmd = Join-Path -Path $tools -ChildPath "MFTECmd.exe" 
$PECmd = Join-Path -Path $tools -ChildPath "PECmd.exe" 
$RBCmd = Join-Path -Path $tools -ChildPath "RBCmd.exe" 
$RecentFileCacheParser = Join-Path -Path $tools  -ChildPath "RecentFileCacheParser.exe"
$ShellBagsParser = Join-Path -Path $tools -ChildPath "SBECmd.exe"

############################################
# Create the export parsed data directories
############################################

$Exports_Path = Join-Path -Path $top_level -ChildPath "Exported_Data"
$Parsed_Path = Join-Path -Path $top_level -ChildPath "Parsed_Data"

New-Item -ItemType directory -Path $Exports_Path -ErrorAction SilentlyContinue
New-Item -ItemType directory -Path $Parsed_Path -ErrorAction SilentlyContinue

Set-Location -Path $Exports_Path

#######################################
# Set Paths based on data collection
#######################################

$RecycleBin = Join-Path -Path $Exports_Path -ChildPath "_Recycle.Bin"
$extend = Join-Path -Path $Exports_Path -ChildPath "_Extend"
$home_dirs = Join-Path -Path $Exports_Path -ChildPath "Users"
$windows  = Join-Path -Path $Exports_Path -ChildPath "Windows"
$system32 = Join-Path -Path $windows -ChildPath "System32"
$winevt =  Join-Path -Path $system32 -ChildPath "winevt"
$event_logs = Join-Path -Path $winevt -ChildPath "Logs"
$registries = Join-Path -Path $system32 -ChildPath "config"
$logfile = Join-Path -Path $Exports_Path -ChildPath "_LogFile"
$mft = Join-Path -Path $Exports_Path -ChildPath "_MFT"
$prefetch = Join-Path -Path $windows -ChildPath "Prefetch"
$usnjrnl  = Join-Path -Path $extend -ChildPath "_UsnJrnl_`$J"
$Secure_SDS = Join-Path -Path $Exports_Path -ChildPath "_Secure_`$SDS"
$boot = Join-Path -Path $Exports_Path -ChildPath "_Boot"
$Logfile = Join-Path -Path $Exports_Path -ChildPath "_LogFile"

$AppCompat = Join-Path -Path $windows -ChildPath "AppCompat"
$AppCompat_Programs = Join-Path -Path $AppCompat -ChildPath "Programs"
$AMCACHE = Join-Path -Path $AppCompat_Programs -ChildPath "Amcache.hve"

$RECENTFILECACHE = Join-Path -Path $AppCompat_Programs -ChildPath "RecentFileCache.bcf"

$SYSTEM = Join-Path -Path $registries -ChildPath "SYSTEM"
$SAM = Join-Path -Path $registries -ChildPath "SAM"
$SOFTWARE = Join-Path -Path $registries -ChildPath "SOFTWARE"
$SECURITY = Join-Path -Path $registries -ChildPath "SECURITY"

#######################################
# Collect the data with Plaso's image_export
#######################################

$collection_filter =  Join-Path -Path $tools -ChildPath "datacollection_filter.txt"
$parameters = " -f " + $collection_filter + " -w " + $Exports_Path + " " + $image_file

if ($host_os -eq 'Win32NT') {
    $image_export = Join-Path -Path $plaso -ChildPath "image_export.exe"
} else {
    $image_export = "image_export.py"
}

$cmd = $image_export + $parameters

Invoke-Expression $cmd

#########################
# Parse the JumpLists
#########################

$output_dir = Join-Path -Path $Parsed_Path  -ChildPath "ParsedJumpLists"
$HOME_Dir = Join-Path -Path  $Exports_Path -ChildPath "Users"
$AppData = "AppData"
$Roaming  = Join-Path -Path $AppData -ChildPath "Roaming"
$Microsoft = Join-Path -Path $Roaming -ChildPath "Microsoft"
$Windows = Join-Path -Path $Microsoft -ChildPath "Windows"
$Recent = Join-Path -Path $Windows -ChildPath "Recent"
$ParsedJumpLists = Join-Path -Path $Parsed_Path -ChildPath "ParsedJumpLists"

$users_accounts = Get-ChildItem -Path $users

New-Item -ItemType directory -Path $ParsedJumpLists -ErrorAction SilentlyContinue

foreach ($USER in $users_accounts) {
    $JumpList = Join-Path -Path $USER.FullName -ChildPath $Recent

    if (Test-Path $JumpList){         
        $out_File = $USER.Name + "_jumplist.csv"
        $user_parsed_jumplist = Join-Path -Path $ParsedJumpLists -ChildPath $out_File
        #$PARAMETERS = " -d " + $JumpList + " --csvf  " +  $user_parsed_jumplist 
        $PARAMETERS = " -d " + $JumpList + " --csv  " +  $ParsedJumpLists 
        $CMD = $JLECmd + $PARAMETERS
        Invoke-Expression $CMD
    } 
}

###################################
# MFT Configs
#######################################

$MFTECmd = Join-Path -Path $tools -ChildPath  "MFTECmd.exe"

$parsed_MFT = Join-Path -Path $Parsed_Path -ChildPath "ParsedMFT"
$mft_export = Join-Path -Path $Exports_Path -ChildPath "_MFT"
$Parameter = " -f " + $mft_export + " --at --csv $parsed_MFT  -bn ParsedMFT.csv"
$body = " -f " + $mft_export + " --body " +  $parsed_MFT + " --bdl C"

$CMD = $MFTECmd + $Parameter
Invoke-Expression $CMD

$cmd = $MFTECmd + $body
Invoke-Expression $CMD

#######################################
# USNJRNL 
#######################################
# Make a body file as well
$j_file = Join-Path -Path $extend -ChildPath "_J"

if (Test-Path $usnjrnl) {
    Copy-Item -Path $usnjrnl -Destination $j_file
    Join-Path -Path $Parsed_Path -ChildPath "ParsedUSNJRNLJ"
    $Parameter = " -f " + $j_file + " --at --csv " + $parsed_MFT  
    $CMD = $MFTECmd + $Parameter
    Invoke-Expression $CMD
}

#######################################
# Secure_SDS 
#######################################
# Make a body file as well
$SDS = Join-Path -Path $Exports_Path -ChildPath "_SDS"

if (Test-Path $usnjrnl) {
    Copy-Item -Path $Secure_SDS -Destination $SDS
    $Parameter = " -f " + $SDS + " --at --csv " + $parsed_MFT  
    $CMD = $MFTECmd + $Parameter
    Invoke-Expression $CMD
}

#######################################
# Boot
#######################################
# Make a body file as well
$Parameter = " -f " + $boot + " --at --csv " + $parsed_MFT  
$CMD = $MFTECmd + $Parameter
Invoke-Expression $CMD

#######################################
# LogFile
#######################################

# Make a body file as well
$Parameter = " -f " + $Logfile + " --at --csv " + $parsed_MFT  
$CMD = $MFTECmd + $Parameter
Invoke-Expression $CMD


#######################################
# Parse the Prefetch
#######################################

$prefetch_parsed = Join-Path -Path $Parsed_Path -ChildPath "ParsedPrefetch"
$Parameter = " -d " +  $prefetch  + " --csv " + $prefetch_parsed
$CMD = $PECmd + $Parameter
Invoke-Expression $CMD

#######################################
# Parse the RecycleBin 
#######################################

$Parsed_RecycleBin = Join-Path $Parsed_Path -ChildPath "ParsedRecycleBin"
$PARAMETERS = " -d " + $RecycleBin + " --csv " + $Parsed_RecycleBin
$CMD = $RBCmd + $PARAMETERS

If (Test-Path -Path $RecycleBin ){ 

    Invoke-Expression $CMD

} else {

   Write-Host $RecycleBin " Not found"
}

#######################################
# Parse the AmCache.hve
#######################################
$PARAMETERS = " -f " + $AMCACHE + " --csv ParsedAmcache -i on"
$CMD = $AmcacheParser + $PARAMETERS
If (Test-Path -Path $AMCACHE){
    Invoke-Expression $CMD

} else {
    Write-Host $AMCACHE" Not Found"

}

####################################################################
# Parse the AppCompatCache/shimcache
####################################################################
$ParsedAppCompatCache = Join-Path -Path $Parsed_Path -ChildPath "ParsedAppCompatCache"
$PARAMETERS = " -f " +  $SYSTEM + "  --csv " + $ParsedAppCompatCache

$CMD = $AppCompatCacheParser + $PARAMETERS

If (Test-Path -Path $SYSTEM){
    Invoke-Expression $CMD
} else {
   Write-Host $SYSTEM" Not Found"
}


############################################################
# Parse the RecentFileCache 
############################################################

$RecentFileCacheParser = Join-Path -Path $tools -ChildPath "RecentFileCacheParser.exe"
$ParsedRecentFileCache = Join-Path -Path $Parsed_Path -ChildPath "ParsedRecentFileCache"

$PARAMETERS = " -f " + $RECENTFILECACHE + " --csv " + $ParsedRecentFileCache

$CMD = $RecentFileCacheParser + $PARAMETERS

If (Test-Path -Path $RECENTFILECACHE){
   Invoke-Expression $CMD
} else {
   Write-Host $RECENTFILECACHE " Not found"
}


############################################################
# Parse the Shellbags
############################################################
 
$ShellBags = Join-Path -Path $Parsed_Path -ChildPath "ParsedShellbags"
$PARAMETERS = " -d " + $registries + " --csv " + $ShellBags 
$CMD = $ShellBagsParser  + $PARAMETERS
Invoke-Expression $CMD

