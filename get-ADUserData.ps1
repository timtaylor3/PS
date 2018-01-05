Import-Module ActiveDirectory

# Pull in list of users in question.
$user_list = Get-Content 'fill in file path and location'
$user_data=@()

# Define properties to retrieve
$properties = @('DisplayName', 'SamAccountName', 'extensionAttribute6', 'Company', 'Department', 'Title', 'PasswordLastSet', 'LastLogonDate', 'Enabled', 'Manager')

foreach ($user in $user_list)
   {
      $user_data += Get-ADUser -filter { mail -like $user } -Property $properties -ErrorAction Continue  | 
                    Select DisplayName, SamAccountName, extensionAttribute6, Company, Department, Title, PasswordLastSet, LastLogonDate, Enabled,@{N='Manager';E={(Get-ADUser $_.Manager).Name}}  
   }

# View data
$user_data | Select-Object -Property $properties| Sort-Object -Property DisplayName -Descending | Format-Table -Property $properties

# Export to CSV
$user_data | Export-Csv 'S:\TimTaylor\ad_output.csv' -NoTypeInformation -Force
