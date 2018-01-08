Import-Module ActiveDirectory

# Expects a two column spaced delimeted text file, no header.
# Column one should be a valid email address, the second column should be a text string which represents a compromised password

# Pull in list of users in question.
$user_list = $user_list = Get-Content 'input file path' 

# Define properties to retrieve
$properties = @('Mail', 'Name', 'SamAccountName', 'extensionAttribute6', 'Company', 'Department', 'Title', 'PasswordLastSet', 'LastLogonDate', 'Enabled', 'Manager' )

#Retreive the data into an array
$user_data=@()

foreach ($user in $user_list)
   {
      $Mail, $Password = $user.Split(" ")

      $user_data += Get-ADUser -filter { mail -like $Mail } -Property $properties -ErrorAction Continue  | 
                    Select Mail, Name, SamAccountName, extensionAttribute6, Company, Department, Title, PasswordLastSet, LastLogonDate, Enabled, @{N='Manager';E={(Get-ADUser $_.Manager).Name}}, 
                                                                                                                                                 @{N='Manager Email';E={(Get-ADUser $_.Manager).UserPrincipalName}}  |
                    Where-object {$_.Enabled -eq "True"} | 
                    Add-Member @{CompromisedPassword=$Password} -PassThru            
   }

# Change the properties to reflect the added fields.
$properties = @( 'Name', 'Mail', 'SamAccountName',  'extensionAttribute6', 'Company', 'Department', 'Title', 'PasswordLastSet', 'LastLogonDate', 'Manager', 'Manager Email', 'CompromisedPassword' )

# Output the data to the screen
$user_data | Sort-Object -Property DisplayName | 
             Format-Table -Property $properties

# Output the data to a CSV
$user_data | Export-Csv 'Output path' -NoTypeInformation -Force
