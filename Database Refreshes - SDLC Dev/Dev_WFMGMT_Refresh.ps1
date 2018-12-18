$DatabaseName = 'WFMGMT'
$BackupLocation = @{
    LiveWFMGMT      = '\\VLOPVRSTOAPP01\SQLBackups_BusApps\BUSAPPS\WFMGMT\FULL'
    SDLCDevFolder   = '\\WERCOVRDEVSQLD1\DBRefresh\ProdBackupFiles\WFMGMT'
}
$SDLC = @{
    SQLInstance              = 'WERCOVRDEVSQLD1'
    DatabaseName             = 'WFMGMT'
    DestinationDataDirectory = 'F:\SQLData'
    DestinationLogDirectory  = 'F:\SQLTLog'
    
}

#Shrink database SQL script
$ShrinkDatabase = @"
    DBCC SHRINKDATABASE(N'$DatabaseName')
"@

#Create folder if not present
if (-not(Test-Path -Path $BackupLocation.SDLCDevFolder)) {New-Item -ItemType directory -Path $BackupLocation.SDLCDevFolder}

#Check and Empty directory if any files exist
Get-ChildItem -Path $BackupLocation.SDLCDevFolder -Include * -File -Recurse | ForEach-Object { $_.Delete()}

write-host 'Copying Latest Backup File to SDLC Dev Server' -ForegroundColor Yellow

#Find the lastest backup file and copy to the SDLC Server
Get-ChildItem -Path $BackupLocation.LiveWFMGMT -Filter "*.bak" -Recurse | 
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


Invoke-Sqlcmd2 -ServerInstance $SDLC.SQLInstance -Database $SDLC.DatabaseName -Query $ShrinkDatabase


