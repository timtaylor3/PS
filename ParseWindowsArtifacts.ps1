<#
- Script by: Tim Taylor
-TODO: Add LECmd to parse lnk files
       Add RECmd to parse select registry keys.
       Cleanup Powershell output
       Reduce the number of workers plaso can use in order to stop the take over of processing power.
       Fix log2time commandline to only run once, instead of looping over parsers options.
       Code Cleanup for repeat commands
       Test for plaso supported input files.
       Add VSC support??  -yes, please
       
-Description
 --Extract key artifacts from an image file using plaso
 --Run selected Eric Zimmerman's Tools against the extracted data
 --Ingest data into plaso for timeline creation
 --Create timelines xlsx and tln timelines
  
 -- Download the tools from these locations: 
     https://github.com/log2timeline/plaso/releases 
     https://ericzimmerman.github.io/#!index.md 

- Version 1.0
  -New Features
  --Added ingestion of data into plaso with output to xlsx and tln
  -Bug fixes
    --Fixed image_export to pull all partitions
    --Fixed Jumplist Parsing
  -Misc
  --Code Cleanup

  -Known Issues
   -- JLECmd.exe -csvf switch didn't work as coded, looking into the issue.
   -- RBCmd.exe can't parse files exported by image_export

 -Tested with:
   --Windows 10
   --Plaso 20180930
   --AmcacheParser 1.2.0.7
   --AppCompatCacheParser 1.3.0.2
   --JLECmd 1.1.0.2
   --LECMD 1.1.0.3 - Testing in Progress
   --MFTECmd 0.3.6.0
   --PECmd 1.2.0.1
   --RBCmd 0.3.0.1
   --RecentFileCacheParser 0.7.0.0
   --SBECmd 1.2.0.0
   --E01 image files
#>

##############################
# Test for Admin if required
##############################
<#
    Future
#>

##############################
# Get User Input
##############################

$top_level = Read-Host -Prompt "Enter Top Level Case Directory"
$image_file = Read-Host -Prompt "Enter the image file to process"

##############################
# Test for supported input image
##############################
<#
    Future work
    $ext = Split-Path -Path $image_file -Extension

    $file_ext = "E01,VHD,dd,raw,VMDK"
    if($ext not in $file_ext){    
        Write-Host "Image type not supported by plaso"
        exit
    }
#>

##############################
# Begin
##############################

$tools = Join-Path -Path $PSScriptRoot -ChildPath "Tools"
$plaso = Join-Path -Path $PSScriptRoot -ChildPath "Plaso"

$image_export = Join-Path -Path $plaso -ChildPath "image_export.exe"
$l2t = Join-Path -Path $plaso -ChildPath "log2timeline.exe"
$psort = Join-Path -Path $plaso -ChildPath "psort.exe" 

$collection_filter =  Join-Path -Path $tools -ChildPath "datacollection_filter.txt"

$AmcacheParser = Join-Path -Path $tools -ChildPath "AmcacheParser.exe" 
$AppCompatCacheParser = Join-Path -Path $tools -ChildPath "AppCompatCacheParser.exe" 
$JLECmd = Join-Path -Path $tools -ChildPath "JLECmd.exe"
$LECmd = Join-Path -Path $tools -ChildPath "LECmd.exe"
$MFTECmd = Join-Path -Path $tools -ChildPath "MFTECmd.exe" 
$PECmd = Join-Path -Path $tools -ChildPath "PECmd.exe" 
#$RBCmd = Join-Path -Path $tools -ChildPath "RBCmd.exe" 
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

# $RecycleBin = Join-Path -Path $Exports_Path -ChildPath "_Recycle.Bin"
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
$RecentFileCache = Join-Path -Path $AppCompat_Programs -ChildPath "RecentFileCache.bcf"

$SYSTEM = Join-Path -Path $registries -ChildPath "SYSTEM"
$SAM = Join-Path -Path $registries -ChildPath "SAM"
$SOFTWARE = Join-Path -Path $registries -ChildPath "SOFTWARE"
$SECURITY = Join-Path -Path $registries -ChildPath "SECURITY"

#######################################
# Collect the data with Plaso's image_export
#######################################

$Parameter = " -f " + $collection_filter + "  --partitions all -w " + $Exports_Path + " " + $image_file
$CMD = $image_export + $Parameter
Invoke-Expression $CMD

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
$users_accounts = Get-ChildItem -Path $HOME_Dir

New-Item -ItemType directory -Path $ParsedJumpLists -ErrorAction SilentlyContinue

foreach ($USER in $users_accounts) {
    $JumpList = Join-Path -Path $USER.FullName -ChildPath $Recent

    if (Test-Path $JumpList){         
        $out_File = $USER.Name + "_jumplist.csv"
        $user_parsed_jumplist = Join-Path -Path $ParsedJumpLists -ChildPath $out_File
        #$Parameter = " -d " + $JumpList + " --csvf  " +  $user_parsed_jumplist 
        $Parameter = " -d " + $JumpList + " --csv  " +  $ParsedJumpLists 
        $CMD = $JLECmd + $Parameter
        Write-Host $CMD
        Invoke-Expression $CMD
    } 
}

#########################
# Parse the lnk files
#########################
<#  Not tested - uncomment and use at your own risk
  $parsed_lnk = Join-Path -Path $Parsed_Path -ChildPath "ParsedLNK"
  New-Item -ItemType directory -Path $parsed_lnk -ErrorAction SilentlyContinue

  $Parameter = " -d " + "-q  --csv "

  $CMD = $MFTECmd + $Parameter
  Write-Host $CMD
  Invoke-Expression $CMD
#>

###################################
# MFT Configs
#######################################

$parsed_MFT = Join-Path -Path $Parsed_Path -ChildPath "ParsedMFT"
$mft_export = Join-Path -Path $Exports_Path -ChildPath "_MFT"
$Parameter = " -f " + $mft_export + " --at --csv $parsed_MFT " + " -bn ParsedMFT.csv"

$CMD = $MFTECmd + $Parameter
Write-Host $CMD
Invoke-Expression $CMD

$body_file = Join-Path -Path $parsed_MFT -ChildPath "ParsedMFT.body"

$body = " -f " + $mft_export + " --body " +  $parsed_MFT + " --bdl C"
$CMD = $MFTECmd + $body
Write-Host $CMD
Invoke-Expression $CMD

#######################################
# USNJRNL 
#######################################
$j_file = Join-Path -Path $extend -ChildPath "_J"

if (Test-Path $usnjrnl) {
    Copy-Item -Path $usnjrnl -Destination $j_file
    Join-Path -Path $Parsed_Path -ChildPath "ParsedUSNJRNLJ"
    $Parameter = " -f " + $j_file + " --at --csv " + $parsed_MFT  
    
    $CMD = $MFTECmd + $Parameter
    Write-Host $CMD
    Invoke-Expression $CMD

    <# Not supported by parser, Leaving for future
    $body = " -f " + $j_file + " --body " +  $parsed_MFT + " --bdl C"
    $CMD = $MFTECmd + $body
    Write-Host $CMD
    Invoke-Expression $CMD
    #>
}

#######################################
# Secure_SDS 
#######################################
$SDS = Join-Path -Path $Exports_Path -ChildPath "_SDS"

if (Test-Path $usnjrnl) {
    Copy-Item -Path $Secure_SDS -Destination $SDS
    $Parameter = " -f " + $SDS + " --at --csv " + $parsed_MFT  

    $CMD = $MFTECmd + $Parameter
    Write-Host $CMD
    Invoke-Expression $CMD

    <# Not supported by parser, Leaving for future
    $body = " -f " +  $SDS + " --body " +  $parsed_MFT + " --bdl C"
    $CMD = $MFTECmd + $body
    Write-Host $CMD
    Invoke-Expression $CMD
    #>
}

#######################################
# Boot
#######################################
if (Test-Path $boot) {
    $Parameter = " -f " + $boot + " --at --csv " + $parsed_MFT  
   $CMD = $MFTECmd + $Parameter
   Write-Host $CMD
   Invoke-Expression $CMD
}

#######################################
# LogFile
#######################################

$Parameter = " -f " + $Logfile + " --at --csv " + $parsed_MFT  
$CMD = $MFTECmd + $Parameter
Write-Host $CMD
Invoke-Expression $CMD

<# Waiting on update to Parser
$body = " -f " +  $Logfile + " --body " +  $parsed_MFT + " --bdl C"
$CMD = $MFTECmd + $body
Write-Host $CMD
Invoke-Expression $CMD
#>

#######################################
# Parse the Prefetch
#######################################

$prefetch_parsed = Join-Path -Path $Parsed_Path -ChildPath "ParsedPrefetch"
$Parameter = " -d " +  $prefetch  + " --csv " + $prefetch_parsed
$CMD = $PECmd + $Parameter
Write-Host $CMD
Invoke-Expression $CMD

#######################################
# Parse the RecycleBin 
#######################################
<#  This won't work due to Plaso swapping the $ to a _ on export.

$Parsed_RecycleBin = Join-Path $Parsed_Path -ChildPath "ParsedRecycleBin"
$Parameter = " -d " + $RecycleBin + " --csv " + $Parsed_RecycleBin
$CMD = $RBCmd + $Parameter
Write-Host $CMD

If (Test-Path -Path $RecycleBin ){ 
    Invoke-Expression $CMD

} else {
   Write-Host $RecycleBin " Not found"
}

#>

#######################################
# Parse the AmCache.hve
#######################################

$ParsedAmCache = Join-Path -Path $Parsed_Path -ChildPath "ParsedAmcache"
$Parameter = " -f " + $AMCACHE + " --csv " + $ParsedAmCache + " -i on"
$CMD = $AmcacheParser + $Parameter
Write-Host $CMD
If (Test-Path -Path $AMCACHE){

    Invoke-Expression $CMD

} else {
    Write-Host $AMCACHE" Not Found"

}

####################################################################
# Parse the AppCompatCache/shimcache
####################################################################

$ParsedAppCompatCache = Join-Path -Path $Parsed_Path -ChildPath "ParsedAppCompatCache"
$Parameter = " -f " +  $SYSTEM + "  --csv " + $ParsedAppCompatCache
$CMD = $AppCompatCacheParser + $Parameter
Write-Host $CMD

If (Test-Path -Path $SYSTEM){
    Invoke-Expression $CMD
} else {
   Write-Host $SYSTEM" Not Found"
}

############################################################
# Parse the RecentFileCache 
############################################################

$ParsedRecentFileCache = Join-Path -Path $Parsed_Path -ChildPath "ParsedRecentFileCache"
$Parameter = " -f " + $RecentFileCache + " --csv " + $ParsedRecentFileCache
$CMD = $RecentFileCacheParser + $Parameter
Write-Host $CMD

If (Test-Path -Path $RECENTFILECACHE){
   Invoke-Expression $CMD
} else {
   Write-Host $RECENTFILECACHE " Not found"
}

############################################################
# Parse the Shellbags
############################################################
 
$ShellBags = Join-Path -Path $Parsed_Path -ChildPath "ParsedShellbags"
$Parameter = " -d " + $HOME_Dir + " --csv " + $ShellBags 
$CMD = $ShellBagsParser  + $Parameter
Write-Host $CMD
Invoke-Expression $CMD

#######################################
# Create a plaso file using the same filter
#######################################

Write-Host "Ingesting MFT related files into Plaso"

$plaso_out_dir = Join-Path -Path $Parsed_Path -ChildPath "Timeline"
$plaso_file = Join-Path -Path $plaso_out_dir -ChildPath "timeline.plaso"

New-Item -ItemType directory -Path $plaso_out_dir -ErrorAction SilentlyContinue

Write-Host "Ingesting Parsed MFT Body File"

$body_files = Get-ChildItem -Path $parsed_MFT | Where-Object {$_.Extension -eq ".body"}

foreach ($body_file in $body_files){
  # This code can be cleaned up.
  $b_file = Join-Path -Path $parsed_MFT -ChildPath $body_file
  $Parameter = " --no_dependencies_check --parsers mactime  --status_view window " + $plaso_file + " " +  $b_file 
  $CMD = $l2t + $Parameter
  Write-host $CMD
  Invoke-Expression $CMD
}

Write-Host "Ingesting Other artifacts from the image file to Plaso"
$parsers = "amcache,custom_destinations,filestat,olecf_automatic_destinations,recycle_bin,prefetch,usnjrnl,winreg"

foreach($parser in $parsers){
    $Parameter = "  --no_dependencies_check -f " + $collection_filter + " --status_view window --partitions all --parsers " +  $parser + " --hashers md5,sha1 " + $plaso_file + " " + $image_file
    $CMD = $l2t + $Parameter
    Write-Host $CMD
    Invoke-Expression $CMD
}

Write-Host "Exporting Excel Spreadsheet"
$xls_file = "timeline.xlsx"
$xls_out = Join-Path -Path $plaso_out_dir  -ChildPath $xls_file 
$Parameter = " -o xlsx -w " + $xls_out + " " + $plaso_file
$CMD = $psort + $Parameter
Write-Host $CMD
Invoke-Expression $CMD

Write-Host "Exporting l2tcsv file"
$tln_file = "timeline.tln"
$tln_out = Join-Path -Path $plaso_out_dir  -ChildPath $tln_file
$Parameter = " -o l2tcsv -w " + $tln_out + " " + $plaso_file
$CMD = $psort + $Parameter
Write-Host $CMD

Write-Host "Finished"
