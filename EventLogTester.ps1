# Returns one event the for the given event log
#  REF: https://blogs.technet.microsoft.com/ashleymcglone/2013/08/28/powershell-get-winevent-xml-madness-getting-details-from-event-logs/

$EVT_PATH = Read-Host -Prompt "Enter the path to the event log"
#$PARSED_EVT = Read-Host -Prompt "Enter output path and filename"

Try {
    #$Events = get-winevent -filterHashTable @{Path=$SEC_PATH;id=4624,4634} -MaxEvents 1
    $Events = get-winevent -filterHashTable @{Path=$EVT_PATH} -MaxEvents 1
    Process_Events($Events) 
    $Events | Select-Object * |
    #Where-Object {($_.LogonType -eq 3) -or ($_.LogonType -eq 10) }|
    #Where-Object TargetUserName -ne "ANONYMOUS LOGON" |
    Format-List
    #Export-Csv -Append  -NoTypeInformation  -Delimiter "," -Path $PARSED_EVT 
                  
} Catch {
    Write-Host "No Events"
}      
 
function Process_Events($Events){
    # Parse out the event message data
    ForEach ($Event in $Events) {            
        # Convert the event to XML            
        $eventXML = [xml]$Event.ToXml()            
        # Iterate through each one of the XML message properties            
        For ($i=0; $i -lt $eventXML.Event.EventData.Data.Count; $i++) {            
            # Append these as object properties     
            Add-Member -InputObject $Event -MemberType NoteProperty -Force `
                -Name  $eventXML.Event.EventData.Data[$i].name `
                -Value $eventXML.Event.EventData.Data[$i].'#text'     
        }            
    }    
    
    return $Events 
}

