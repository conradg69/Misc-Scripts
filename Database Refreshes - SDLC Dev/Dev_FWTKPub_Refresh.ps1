$DatabaseName = 'FusionWebToolkitPub'
$BackupLocation = @{
    LiveBackupFile    = '\\VLOPVRSTOAPP01\SQL_Backups_Traveller\TRAVELLERSQLCL\FusionWebToolkitPub\FULL'
    SDLCFolder    = '\\WERCOVRDEVSQLD1\DBRefresh\ProdBackupFiles\FusionWebToolkitPub'
    SDLCDiff = '\\WERCOVRDEVSQLD1\DBRefresh\ProdBackupFiles\FusionWebToolkitPub\DIFF'
}
$SDLC = @{
    SQLInstance              = 'WERCOVRDEVSQLD1'
    DatabaseName             = 'FusionWebToolkitPub'
    DestinationDataDirectory = 'F:\SQLData'
    DestinationLogDirectory  = 'F:\SQLTLog'
    
}

#Create folder if not present
if (-not(Test-Path -Path $BackupLocation.SDLCFolder)) {New-Item -ItemType directory -Path $BackupLocation.SDLCFolder}

#Check and Empty directory if any files exist
Get-ChildItem -Path $BackupLocation.SDLCFolder -Include * -File -Recurse | ForEach-Object { $_.Delete()}

write-host 'Copying Latest Backup File to SDLC Dev Server' -ForegroundColor Yellow

#Find the lastest backup file and copy to the SDLC Server
Get-ChildItem -Path $BackupLocation.LiveBackupFile -Filter "*.bak" -Recurse | 
Sort-Object LastWriteTime -Descending | Select-Object -First 1  |
Copy-Item  -Destination $BackupLocation.SDLCFolder -Verbose

#Find the lastest DIFF backup file and copy to the SDLC Server
Get-ChildItem -Path $BackupLocation.LiveBackupFile -Filter "*.diff" -Recurse | 
Sort-Object LastWriteTime -Descending | Select-Object -First 1  |
Copy-Item  -Destination $BackupLocation.SDLCDiff -Verbose


write-host 'Backup File Copy Complete' -ForegroundColor Yellow

write-host 'Restoring'$SDLC.DatabaseName 'Database' -ForegroundColor Yellow

#Restore Database from Backups
$restoreDbaDatabaseSplat = @{
    SqlInstance = $SDLC.SQLInstance
    Path = $BackupLocation.SDLCFolder
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

#Shrink database
$ShrinkDatabase = @"
    DBCC SHRINKDATABASE(N'"$DatabaseName"')
"@
Invoke-Sqlcmd2 -ServerInstance $SDLC.SQLInstance -Database $SDLC.DatabaseName -Query $ShrinkDatabase -QueryTimeout ([int]::MaxValue) -Verbose


