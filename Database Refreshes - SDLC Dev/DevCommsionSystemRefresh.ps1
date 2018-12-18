$BackupLocation = @{
    CommissionSystem = '\\VLOPVRSTOAPP01\SQLBackups_BusApps\BUSAPPS\CommissionSystem\FULL'
    SDLCDevFolder = '\\WERCOVRDEVSQLD1\DBRefresh\ProdBackupFiles\CommissionSystem'
}
$SDLC = @{
    SQLInstance = 'WERCOVRDEVSQLD1'
    DatabaseName = 'CommissionSystem'
    DestinationDataDirectory = 'H:\SQLData'
    DestinationLogDirectory = 'H:\SQLTLog'
}


#Create folder if not present
if (-not(Test-Path -Path $BackupLocation.SDLCDevFolder)) {New-Item -ItemType directory -Path $BackupLocation.SDLCDevFolder}

#Check and Empty directory if any files exist
Get-ChildItem -Path $BackupLocation.SDLCDevFolder -Include * -File -Recurse | foreach { $_.Delete()}

write-host 'Copying Latest Backup File to SDLC Dev Server' -ForegroundColor Yellow

#Find the lastest backup file and copy to the SDLC Dev Server
Get-ChildItem -Path $BackupLocation.CommissionSystem -Filter "*.bak" -Recurse | Sort-Object LastWriteTime -Descending |
Select-Object -First 1  |Copy-Item  -Destination $BackupLocation.SDLCDevFolder -Verbose

write-host 'Backup File Copy Complete' -ForegroundColor Yellow
write-host 'Restoring'$SDLC.DatabaseName 'Database' -ForegroundColor Yellow

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
