$Server = 'WERCOVRDEVSQLD1'
$DevDatabase = 'TR4_DEV'
$Accounts = @{
    DBO       = 'TravellerAppTR4Dev', 'TravellerAppDev', 'BreaseAppDev', 'VRGUK\WebAppsUsers', 'VRGUK\WebsiteDataBuilder', 'VRGUK\SDLCQae', 'VRGUK\SDLCDev', 'macbuild'
    ReadWrite = 'TravellerReportingDev', 'BabelDirectAppDEV', 'RCINJ\ctrq664', 'YMTSASUser', 'VRGUK\andrewtaylor', 'EpicPricingUpload', 'VRGUK\jeanbaptistetherasse', 'VRGUK\Finance_Trav_Reporting', 'VRGUK\douglaswatson', 'VRGUK\dianewebber', 'VRGUK\SDLCSQLAgentUAT', 'VRGUK\SDLCSQLAgentQAE'
    Read      = 'vrguk\earnpsql'
}
$TravellerLiveBackupLocation = @{
    FULLBackup = '\\WERCOVRUATSQLD1\DBBackups4\TR4_LIVE\FULL'
    DIFFBackup = '\\WERCOVRUATSQLD1\DBBackups2\TR4_LIVE\LOG'  
}
$FULLBackupFileDetails = (Get-ChildItem -Path $TravellerLiveBackupLocation.FULLBackup -Filter "*.bak" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$DIFFBackupFileDetails = (Get-ChildItem -Path $TravellerLiveBackupLocation.DIFFBackup -Filter "*.diff" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName

$TR4DevSetupSanitise = '\\Wercovrdevsqld1\ps\SQLRefreshJobs\TR4Dev\TR4DevSetup&Sanitise.sql'
$TR4DevSetupTravellerAcess = '\\Wercovrdevsqld1\ps\SQLRefreshJobs\TR4Dev\SetupTravellerAccess.sql'
$UpdateSYNONYMs = '\\Wercovrdevsqld1\ps\SQLRefreshJobs\TR4Dev\UpdateSynonyms.sql'
$CLR = '\\Wercovrdevsqld1\ps\SQLRefreshJobs\TR4Dev\CLR.sql'

$SQLQueries = @{
    CDCQuery                 = "EXEC sys.sp_cdc_add_job 'capture'"
    TR4_DEVFULLRestoreScript = @"
    Alter database $DevDatabase set single_user with rollback immediate 
    Alter database $DevDatabase set multi_user with rollback immediate 
    RESTORE DATABASE $DevDatabase
    FROM  DISK = '$FULLBackupFileDetails'
    WITH    
    MOVE N'Tr@veller_Data' TO N'I:\SQLData\TR4_DEV.mdf',  
    MOVE N'Traveller_Data2' TO N'I:\SQLData\TR4_DEV_1.ndf',
    MOVE 'Traveller_AddData' TO 'P:\SQLData\TR4_DEV_2.ndf',  
    MOVE 'Tr@veller_Log' TO 'F:\SQLTLog\TR4_DEV_3.ldf',
    MOVE 'Tr@veller_Log2' TO 'F:\SQLTLog\TR4_Live_Log2.ldf',
    REPLACE, NORECOVERY,  STATS = 5   
"@

    TR4_DEVDIFFRestoreScript = @"
    RESTORE DATABASE $DevDatabase
    FROM  DISK = '$DIFFBackupFileDetails'
    WITH  RECOVERY, KEEP_CDC, STATS = 5  

    ALTER DATABASE $DevDatabase SET RECOVERY SIMPLE
"@

    TR4_DEVShrinkLogScript = @"
    ALTER DATABASE $DevDatabase SET RECOVERY SIMPLE
    DBCC SHRINKFILE('Tr@veller_Log', 3024)
"@

    ChangeDefaultCursortoGLOBAL = @"
    ALTER DATABASE $DevDatabase SET CURSOR_DEFAULT  GLOBAL WITH NO_WAIT
"@
  
}



<#
#SORT THIS OUT
/****** Object:  Schema [VRGUK\WebTeamReadOnly]    Script Date: 03/29/2015 22:53:09 ******/
IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'VRGUK\WebTeamReadOnly')
DROP SCHEMA [VRGUK\WebTeamReadOnly]
GO


Also find a way to add this or check if it's actuallt still needed
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'DataLink_GoldmineTraveller')
BEGIN
	CREATE USER DataLink_GoldmineTraveller FOR LOGIN DataLink_GoldmineTraveller WITH DEFAULT_SCHEMA = dbo
--	EXEC sp_addrolemember N'db_datareader', N'DataLink_GoldmineTraveller'
	EXEC sp_addrolemember N'db_denydatawriter', N'DataLink_GoldmineTraveller'
	grant select on Attribute to DataLink_GoldmineTraveller
grant select on Feature to DataLink_GoldmineTraveller
grant select on HosServiceExtras to DataLink_GoldmineTraveller
grant select on HosSupplierExtras to DataLink_GoldmineTraveller
grant select on HosUnitExtras to DataLink_GoldmineTraveller
grant select on KeyHolder to DataLink_GoldmineTraveller
grant select on Service to DataLink_GoldmineTraveller
grant select on Supplier to DataLink_GoldmineTraveller
grant select on Thg_SupplierGeoLocationDetail to DataLink_GoldmineTraveller
grant select on Unit to DataLink_GoldmineTraveller

CREATE USER [VRGUK\dianewebber] FOR LOGIN [VRGUK\dianewebber]
		EXEC sp_addrolemember N'db_datareader', N'VRGUK\dianewebber'
		EXEC sp_addrolemember N'db_denydatawriter', N'VRGUK\dianewebber'	
		GRANT EXECUTE ON SCHEMA::dbo TO [VRGUK\dianewebber]
        GRANT showplan to [VRGUK\dianewebber]
        
CREATE USER [VRGUK\douglaswatson] FOR LOGIN [VRGUK\douglaswatson]
		EXEC sp_addrolemember N'db_datareader', N'VRGUK\douglaswatson'
		EXEC sp_addrolemember N'db_denydatawriter', N'VRGUK\douglaswatson'	
		GRANT EXECUTE ON SCHEMA::dbo TO [VRGUK\douglaswatson]
        GRANT showplan to [VRGUK\douglaswatson]
        
CREATE USER [VRGUK\SDLCSQLAgentUAT] FOR LOGIN [VRGUK\SDLCSQLAgentUAT]
		EXEC sp_addrolemember N'db_datareader', N'VRGUK\SDLCSQLAgentUAT'
		EXEC sp_addrolemember N'db_denydatawriter', N'VRGUK\SDLCSQLAgentUAT'	
		GRANT EXECUTE ON SCHEMA::dbo TO [VRGUK\SDLCSQLAgentUAT]
        GRANT showplan to [VRGUK\SDLCSQLAgentUAT]
       
CREATE USER [VRGUK\SDLCSQLAgentQAE] FOR LOGIN [VRGUK\SDLCSQLAgentQAE]
		EXEC sp_addrolemember N'db_datareader', N'VRGUK\SDLCSQLAgentQAE'
		EXEC sp_addrolemember N'db_denydatawriter', N'VRGUK\SDLCSQLAgentQAE'	
		GRANT EXECUTE ON SCHEMA::dbo TO [VRGUK\SDLCSQLAgentQAE]
		GRANT showplan to [VRGUK\SDLCSQLAgentQAE]
#>

#Restore FULL Backup
Invoke-Sqlcmd2 -ServerInstance $Server -Database Master -Query $SQLQueries.TR4_DEVFULLRestoreScript -QueryTimeout ([int]::MaxValue) -Verbose

Write-Host '*********FULL BACKUP COMPLETE***************' 
Write-Host '*********DIFF BACKUP Stared***************'
#Restore DIFF Backup  
Invoke-Sqlcmd2 -ServerInstance $Server -Database Master -Query $SQLQueries.TR4_DEVDIFFRestoreScript -QueryTimeout ([int]::MaxValue) -Verbose

#CDC
Invoke-Sqlcmd2 -ServerInstance $Server -Database $DevDatabase -Query $SQLQueries.CDCQuery -QueryTimeout ([int]::MaxValue) -Verbose

#Drop all database users
$DBUsers = Get-DbaDatabaseUser $Server -Database $DevDatabase -ExcludeSystemUser |
Where-Object -FilterScript {$_.Name -ne 'cdc'} | Where-Object {$_.Name -ne 'AutoTaskExecuter'}
$DBUsers.Name | ForEach-Object {Remove-DbaDbUser -SqlInstance $Server -Database $DevDatabase -User $_}

#Add Accounts
$Accounts.DBO | ForEach-Object{New-DbaDbUser -SqlInstance $Server -Database $DevDatabase -Login $_ -Username $_} 
$Accounts.ReadWrite | ForEach-Object{New-DbaDbUser -SqlInstance $Server -Database $DevDatabase -Login $_ -Username $_} 
$Accounts.Read | ForEach-Object{New-DbaDbUser -SqlInstance $Server -Database $DevDatabase -Login $_ -Username $_} 

#Add account to the DBO role
$Accounts.DBO | ForEach-Object{
    $GrantDBOPermissions = @"
    EXEC sp_addrolemember N'db_owner', N'$_'
"@
    Invoke-Sqlcmd2 -ServerInstance $Server -Database $DevDatabase -Query $GrantDBOPermissions
}
#Add account to the READ\Write role
$Accounts.ReadWrite | ForEach-Object{
    $GrantReadWritePermissions = @"
    EXEC sp_addrolemember N'db_datareader', N'$_'
	EXEC sp_addrolemember N'db_denydatawriter', N'$_'
"@
    Invoke-Sqlcmd2 -ServerInstance $Server -Database $DevDatabase -Query $GrantReadWritePermissions
}

#Shrink Log
Invoke-Sqlcmd2 -ServerInstance $Server -Database $DevDatabase -Query $SQLQueries.TR4_DEVShrinkLogScript -QueryTimeout ([int]::MaxValue) -Verbose

#Setup and Sanitise Traveller
Invoke-Sqlcmd2 -ServerInstance $Server -Database $DevDatabase -InputFile $TR4DevSetupSanitise -QueryTimeout ([int]::MaxValue) -Verbose

#Setup Traveller Access
Invoke-Sqlcmd2 -ServerInstance $Server -Database $DevDatabase -InputFile $TR4DevSetupTravellerAcess -QueryTimeout ([int]::MaxValue) -Verbose

#ChangeDefaultCursortoGLOBAL
Invoke-Sqlcmd2 -ServerInstance $Server -Database $DevDatabase -Query $SQLQueries.ChangeDefaultCursortoGLOBAL -QueryTimeout ([int]::MaxValue) -Verbose

#Update Synonyms
Invoke-Sqlcmd2 -ServerInstance $Server -Database $DevDatabase -InputFile $UpdateSYNONYMs -QueryTimeout ([int]::MaxValue) -Verbose

#Load CLR
Invoke-Sqlcmd2 -ServerInstance $Server -Database $DevDatabase -InputFile $CLR -QueryTimeout ([int]::MaxValue) -Verbose





#Backup Destinations on the SDLC Dev Server
$SDLCDev39BackupFolder = "\\WERCOVRDEVSQLD1\PreProd Refresh\DBBackups\Fusion39Backups"
$SDLCDevILTBackupFolder = "\\WERCOVRDEVSQLD1\PreProd Refresh\DBBackups\FusionILTCacheSearchBackup"
$SDLCBreaseBackupFolder = "\\WERCOVRDEVSQLD1\PreProd Refresh\DBBackups\BreaseBackup"
$UserpermissionsScriptOutput = "\\WERCOVRDEVSQLD1\PreProd Refresh\LoginScripts\UserPermissions.sql" 
$UATSQLInstance = 'Wercovruatsqld1,2533'
$DropReplicationScript = '\\WERCOVRDEVSQLD1\PreProd Refresh\DropReplication.sql'
$TravellerLiveBackup = '\\WERCOVRUATSQLD1\DBBackups4\TR4_LIVE\FULL'
$TravellerLiveBackupFile = Get-ChildItem -Path '\\WERCOVRUATSQLD1\DBBackups4\TR4_LIVE\FULL'
$TravellerLiveBackupFile2 = $TravellerLiveBackupFile.FullName
$BreaseDatabase = 'BeaseUAT'

#Brease Setup Files
$BreaseUATConfigFile = '\\WERCOVRDEVSQLD1\PreProd Refresh\BreaseUAT.sql'
$BreaseAccountPermissions = '\\WERCOVRDEVSQLD1\PreProd Refresh\Brease Account Access.sql'

#Invoke-Item '\\10.215.13.143\SQLBackups1\Fusion\Fusion39\HoseasonsAPI\FULL'

#1. Loop through each folder, find the latest backup and copy to the SDLC Dev server
ForEach ($BackupFolder in $Fusion39Backups) {
    Get-ChildItem -Path $BackupFolder -Filter "*.bak" -Recurse|
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1 |
        ForEach-Object($_) {Copy-Item $_.FullName -Destination $SDLCDev39BackupFolder -Verbose
    }
} 

#2. Get the details for the latest ILT backup from Live and copy to the SDLC server
Get-ChildItem -Path $FusionILTCacheSearchBackups -Filter "*.bak" -Recurse | Sort-Object LastWriteTime -Descending |
    Select-Object -First 1  |Copy-Item  -Destination $SDLCDevILTBackupFolder -Verbose

#3. Get the details for the latest Brease backup from Live and copy to the SDLC server
Get-ChildItem -Path $BreaseLiveBackup -Filter "*.bak" -Recurse | Sort-Object LastWriteTime -Descending |
    Select-Object -First 1  |Copy-Item  -Destination $SDLCBreaseBackupFolder -Verbose

#4. Export user accounts for all Fusion 3.9 databases
Export-DbaUser -SqlInstance $UATSQLInstance -Database $Databases -FilePath $UserpermissionsScriptOutput 

#5. Restore all 12 Fusion 3.9 database from the SDLC Dev folder
$restoreDbaDatabaseSplat = @{
    SqlInstance   = $UATSQLInstance
    Path          = '\\WERCOVRDEVSQLD1\PreProd Refresh\DBBackups\Fusion39Backups'
    WithReplace   = $true
    Verbose       = $true
    AllowContinue = $true
    WhatIf        = $true
}
Restore-DbaDatabase @restoreDbaDatabaseSplat


#6. Drop PreProd Replication
Invoke-DbaSqlQuery -SqlInstance $UATSQLInstance -Database TR4_PRE_PROD -File $DropReplicationScript -Verbose

<#
#7. restore Traveller Database ??? Issues

#FULL TR4_DEV restore taken from SSIS package and tested (working)
$TravellerFullBackup = Get-ChildItem -Path '\\WERCOVRUATSQLD1\DBBackups4\TR4_LIVE\FULL\' -Filter "*.bak" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$TravellerFullBackupFilePath = $TravellerFullBackup.FullName

$TR4_DEVRestoreScript = @"
    --Alter database TR4_DEV set single_user with rollback immediate 
    --Alter database TR4_DEV set multi_user with rollback immediate 
    RESTORE DATABASE TR4_DEV
    FROM  DISK = '$TravellerFullBackupFilePath'
    WITH    
    MOVE N'Tr@veller_Data' TO N'I:\SQLData\TR4_DEV.mdf',  
    MOVE N'Traveller_Data2' TO N'I:\SQLData\TR4_DEV_1.ndf',
    MOVE 'Traveller_AddData' TO 'P:\SQLData\TR4_DEV_2.ndf',  
    MOVE 'Tr@veller_Log' TO 'F:\SQLTLog\TR4_DEV_3.ldf',
    MOVE 'Tr@veller_Log2' TO 'F:\SQLTLog\TR4_Live_Log2.ldf',
    REPLACE, NORECOVERY,  STATS = 5
"@
    Invoke-Sqlcmd2 -ServerInstance WERCOVRDEVSQLD1 -Database Master -Query $TR4_DEVRestoreScript -QueryTimeout ([int]::MaxValue) -Verbose



Restore-DbaDatabase -SqlInstance $UATSQLInstance -DatabaseName TR4_PRE_PROD -Path $TravellerLiveBackup -WithReplace -NoRecovery -Verbose -WhatIf
$inputFile='\\WERCOVRDEVSQLD1\PreProd Refresh\TravellerFULLRefresh.sql'
$BackupFile='\\WERCOVRUATSQLD1\DBBackups4\TR4_LIVE\FULL\TR4_LIVE.FULLCOMP.20180914200000.BAK'

Invoke-DbaSqlQuery -SqlInstance $UATSQLInstance -Database Master -File $inputFile -Verbose
#>

#8. Apply Traveller setup, DB permissions, Traveller Access levels and load CLR

#9. Backup the current UAT Brease Database
Backup-DbaDatabase -SqlInstance $UATSQLInstance -Database BreaseUAT -BackupDirectory K:\DBBackups\BreaseUAT\FULL -CompressBackup

#10. Refresh the UAT Brease database
$restoreDbaDatabaseSplat = @{
    SqlInstance              = $UATSQLInstance
    Path                     = $SDLCBreaseBackupFolder
    WithReplace              = $true
    Verbose                  = $true
    DatabaseName             = 'BreaseUAT'
    DestinationDataDirectory = 'K:\SQLData'
    DestinationLogDirectory  = 'K:\SQLTLog'
}
Restore-DbaDatabase @restoreDbaDatabaseSplat

#11. Apply Brease UAT configuration
Invoke-DbaSqlQuery -SqlInstance $UATSQLInstance -Database BreaseUAT -File $BreaseUATConfigFile -Verbose

#12. Grant the BreaseUAT account DBO permissions to the Brease database
Invoke-DbaSqlCmd -SqlInstance $UATSQLInstance -Database BreaseUAT -File $BreaseAccountPermissions -Verbose

#Additonal BreaseUAT permissions to add
<#
USE [BreaseUAT]
GO
CREATE USER [SSRSUser2] FOR LOGIN [SSRSUser2]
GO
USE [BreaseUAT]
GO
EXEC sp_addrolemember N'db_owner', N'SSRSUser2'
GO
#>

#Refresh the ILT PreProd database
$restoreDbaDatabaseSplat = @{
    SqlInstance              = $UATSQLInstance
    Path                     = $SDLCDevILTBackupFolder
    DestinationFileSuffix    = 'PreProd'
    Verbose                  = $true
    DatabaseName             = 'FusionILTCacheSearchPreProd'
    DestinationDataDirectory = 'F:\SQLData'
    DestinationLogDirectory  = 'F:\SQLTLog'
    WithReplace              = $true
}
Restore-DbaDatabase @restoreDbaDatabaseSplat

#Add replciation
#Run script
#start agent job

#Add ILT Index

#LOAD CLR


#Checks
#Check Traveller and ILT CLR loaded



