Function Format-TravellerReplicationScript {

    
    $LIVE = @{
        DatabaseName            = 'TR4_LIVE'
        Server                  = 'TRAVELLERSQLCL'
        DBAGroup                = "VRGUK\SQL_DBA (Earby)"
        ReplicationScriptFolder = '\\VLOPVRSTOAPP01\SQL_Backups_Traveller\TravellerScriptedObjects\Replication'
    }

    $SDLC = @{
        DatabaseName         = 'TR4_DEV'
        Server               = 'WERCOVRDEVSQLD1'
        FusionILTCacheSearch = 'FusionILTCacheSearchDEV'
        UpdateParameter1     = "vrguk\ProdSQLServer"
        UpdateParameter2     = "VRGUK\ProdSQLServerAgent"
        UpdateParameter3     = "VRGUK\ProdTRAVSQLAgentServ"
        UpdateParameter4     = "TRAVELLERSQLCL"
        UpdateParameter5     = "VRGUK\SQL_DBA (Earby)"
        SDCLScriptLocation   = '\\Wercovrdevsqld1\dba\EnvironmentRefresh\DEV\Replication\SDLCCopy'
        LiveScriptLocation   = '\\Wercovrdevsqld1\dba\EnvironmentRefresh\DEV\Replication\LiveTraveller'
    }

    #Check and create folders if required
    if ( -Not (Test-Path -Path $SDLC.LiveScriptLocation ) ) {
        New-Item -ItemType directory -Path $SDLC.LiveScriptLocation
    }
    if ( -Not (Test-Path -Path $SDLC.SDCLScriptLocation ) ) {
        New-Item -ItemType directory -Path $SDLC.SDCLScriptLocation
    }

    #Copy Script from Live Server
    $FromLiveReplicationScript = Get-ChildItem -Path $LIVE.ReplicationScriptFolder -Recurse -Include *.sql |
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1

    #Copy from Live to the Live SDLC Folder
    Copy-Item $FromLiveReplicationScript.FullName -Destination $SDLC.LiveScriptLocation

    #get the latest file from the SDLC Live Folder
    $LiveReplicationScript = Get-ChildItem -Path $SDLC.LiveScriptLocation -Recurse -Include *.sql |
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1

    #Make a copy of the script in a separate folder
    Copy-Item $LiveReplicationScript.FullName -Destination $SDLC.SDCLScriptLocation

    $SDLCReplicationScriptCopy = Get-ChildItem $SDLC.SDCLScriptLocation  -Recurse -Include *.sql| 
        Sort-Object LastWriteTime -Descending | Select-Object -First 1


    (Get-Content $SDLCReplicationScriptCopy.FullName).Replace($LIVE.DatabaseName, $SDLC.DatabaseName)|Set-Content  $SDLCReplicationScriptCopy.FullName 
    (Get-Content $SDLCReplicationScriptCopy.FullName).Replace($SDLC.UpdateParameter1, $LIVE.DBAGroup) | Set-Content $SDLCReplicationScriptCopy.FullName 
    (Get-Content $SDLCReplicationScriptCopy.FullName).Replace($SDLC.UpdateParameter2, $LIVE.DBAGroup) | Set-Content $SDLCReplicationScriptCopy.FullName
    (Get-Content $SDLCReplicationScriptCopy.FullName).Replace($SDLC.UpdateParameter3, $LIVE.DBAGroup) | Set-Content $SDLCReplicationScriptCopy.FullName
    (Get-Content $SDLCReplicationScriptCopy.FullName).Replace($LIVE.Server, $SDLC.Server) | Set-Content $SDLCReplicationScriptCopy.FullName

}



<#

$DropReplicationScript = @"
EXEC sp_dropsubscription 
  @publication = N'pubFusionILTCache', 
  @article = N'all',
  @subscriber = 'WERCOVRDEVSQLD1';
GO

-- Remove a transactional publication.
EXEC sp_droppublication @publication = N'pubFusionILTCache';
"@


#Drop the Current replication. Pulication and Subscribers
Invoke-DbaQuery -SqlInstance $SDLC.Server -Database $SDLC.DatabaseName -Query $DropReplicationScript -Verbose

Invoke-DbaQuery -SqlInstance $SDLC.Server -Database $SDLC.DatabaseName -File $SDLCReplicationScriptCopy.FullName -Verbose




 Get-ChildItem -Path $BackupLocation.LiveBackupFile -Filter "*.bak" -Recurse | 
    Sort-Object LastWriteTime -Descending | Select-Object -First 1  |
    Copy-Item  -Destination $BackupLocation.SDLCFolder -Verbose

    if ( -Not (Test-Path -Path $ModifiedScriptFolder ) ) {
    New-Item -ItemType directory -Path $ModifiedScriptFolder
}

#>
