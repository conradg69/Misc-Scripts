
$BackupLocation = @{
    FusionAvailabilityCache = '\\VLOPVRSTOAPP01\SQL_Backups_Traveller\TRAVELLERSQLCL\FusionAvailabilityCache\FULL'
    SDLCDevFolder = '\\WERCOVRDEVSQLD1\DBRefresh\ProdBackupFiles\FusionAvailabilityCache'
}
$SDLC = @{
    SQLInstance = 'WERCOVRDEVSQLD1'
    DatabaseName = 'FusionAvailabilityCacheDev'
    DestinationDataDirectory = 'H:\SQLData'
    DestinationLogDirectory = 'H:\SQLTLog'
    Accounts = 'VRGUK\WebTeamReadOnly','VRGUK\Web Dev Team','VRGUK\SDLCQae','VRGUK\SDLCDev','VRGUK\devarajramasamy'
}


#Create folder if not present
if (-not(Test-Path -Path $BackupLocation.SDLCDevFolder)) {New-Item -ItemType directory -Path $BackupLocation.SDLCDevFolder}

#Check and Empty directory if any files exist
Get-ChildItem -Path $BackupLocation.SDLCDevFolder -Include * -File -Recurse | ForEach-Object { $_.Delete()}

write-host 'Copying Latest Backup File to SDLC Dev Server' -ForegroundColor Yellow

#Find the lastest backup file and copy to the SDLC Dev Server
Get-ChildItem -Path $BackupLocation.FusionAvailabilityCache -Filter "*.bak" -Recurse | 
Sort-Object LastWriteTime -Descending | Select-Object -First 1  |
Copy-Item  -Destination $BackupLocation.SDLCDevFolder -Verbose

write-host 'Backup File Copy Complete' -ForegroundColor Yellow

write-host 'Restoring'$SDLC.DatabaseName 'Database' -ForegroundColor Yellow

#Restore Database
$restoreDbaDatabaseSplat = @{
    SqlInstance = $SDLC.SQLInstance
    Path = $BackupLocation.SDLCDevFolder
    WithReplace = $true
    Verbose = $true
    DatabaseName = $SDLC.DatabaseName
    DestinationDataDirectory = $SDLC.DestinationDataDirectory
    DestinationLogDirectory = $SDLC.DestinationLogDirectory
}
Restore-DbaDatabase @restoreDbaDatabaseSplat

#Drop all database users
$DBUsers = Get-DbaDatabaseUser $SDLC.SQLInstance -Database $SDLC.DatabaseName -ExcludeSystemUser 
$DBUsers.Name | ForEach-Object {Remove-DbaDbUser -SqlInstance $SDLC.SQLInstance -Database $SDLC.DatabaseName -User $_}

#Add new accounts to the database
$SDLC.Accounts | ForEach-Object{New-DbaDbUser -SqlInstance $SDLC.SQLInstance -Database $SDLC.DatabaseName -Login $_ -Username $_} 

#Add account to the DBO role
$SDLC.Accounts | ForEach-Object{
    
    $GrantDBOPermissions = @"
    EXEC sp_addrolemember N'db_owner', N'$_'
"@
    Invoke-Sqlcmd2 -ServerInstance $SDLC.SQLInstance -Database $SDLC.DatabaseName -Query $GrantDBOPermissions
}

#Shrink database Logfile
$ShrinklogFile = @"
    DBCC SHRINKFILE (N'FusionAvailabilityCache_log' , 0)
"@
Invoke-Sqlcmd2 -ServerInstance $SDLC.SQLInstance -Database $SDLC.DatabaseName -Query $ShrinklogFile


