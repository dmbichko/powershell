Import-Module sqlserver
$serverInstance = "10.1.10.9"
$User = 'sa'
$backupDirectory='C:\var\opt\mssql\data\backup'
# Convert plain text into a secure string
$Pass = Get-Content D:\BackUp1с83\sql.txt |ConvertTo-SecureString
#supply the $Pass variable as SecureString for the password
$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$Pass
#Build the connection
[reflection.assembly]::Load("Microsoft.SqlServer.Smo, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91") | Out-NULL

$server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $serverInstance
# Set credentials
$server.ConnectionContext.LoginSecure=$false
$server.ConnectionContext.set_Login($Credentials.UserName)
$server.ConnectionContext.set_SecurePassword($credentials.Password)
# Connect to the Server and get a few properties
#$dbs = $server.Databases | where { $_.IsSystemObject -eq $False }
$dbs = $server.Databases | where { ($_.Name -like "meat*") -and ($_.Name -notlike "meat_ubuntu") }
#Looping through every databases
foreach ($database in $dbs)
{
    $dbName = $database.Name
    $timestamp = Get-Date -format yyyy-MM-dd-HHmmss
    $targetPath = $backupDirectory + "\" + $dbName + "_" + $timestamp + ".bak"
    #Define tackup object that will be used for the database backup    
    $smoBackup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")
    # To perform the full backup  z
    $smoBackup.Action = "Database"
    # To turnoff  Differential backup     
    $smoBackup.Incremental = $False
    #Specify the backup description so that we know what this backup is and when it was taken.
    $smoBackup.BackupSetDescription = "Full Backup of " + $dbName
    $smoBackup.BackupSetName = $dbName + " Backup"
    $smoBackup.Database = $dbName
    $smoBackup.MediaDescription = "Disk"
    # Add a backup device using AddDevice() method to a file.   
    $smoBackup.Devices.AddDevice($targetPath, "File")
    #Initiate Database Backup
    $smoBackup.SqlBackup($server)
    write-host "FULL back up $dbName ($serverName) to $targetPath"
}