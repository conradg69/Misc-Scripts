Function Invoke-ScriptOutTravellerReplication {

    $CurrentDateTime = Get-Date -Format FileDateTime 
    $DateTimeFormatted = $CurrentDateTime.Substring(0, 13)
    $ScriptOutputFolder = '\\VLOPVRSTOAPP01\SQL_Backups_Traveller\TravellerScriptedObjects\Replication\'
    $FileName = 'Traveller_ILT_ReplicationExport_'+ $DateTimeFormatted + '.sql'
    $PublicationScript = $ScriptOutputFolder+$FileName

    $SDLCScriptCopy = @(
        "\\Wercovrdevsqld1\dba\EnvironmentRefresh\DEV\Replication\LiveTraveller", 
        "\\Wercovrqaesqld1\dba\EnvironmentRefresh\QAE\Replication\LiveTraveller",
        "\\Wercovruatsqld1\dba\EnvironmentRefresh\UAT\Replication\LiveTraveller" 
        )

    $Script = {

        $servername = 'TravellerSQLCL'
        $databasename = 'TR4_LIVE'
        $publication_name = 'pubFusionILTCache'        
        

        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Rmo") |Out-Null
        $repserver = New-Object "Microsoft.SqlServer.Replication.ReplicationServer"
        $srv = New-Object "Microsoft.SqlServer.Management.Common.ServerConnection" $servername
        $srv.connect()
        $repserver.ConnectionContext = $srv
        $repdb = $repserver.ReplicationDatabases[$databasename]
        $publication_object = $repdb.transpublications[$publication_name]
    
        #$publication_object| Get-Member

        $script_val = [Microsoft.SqlServer.Replication.ScriptOptions]::Creation -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludeEnableReplicationDB -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludeCreateSnapshotAgent   -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludePublications -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludePublicationAccesses -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludeArticles -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludeGo
        #[Microsoft.SqlServer.Replication.ScriptOptions]::IncludeAll  -bxor
        #[Microsoft.SqlServer.Replication.ScriptOptions]::IncludeReplicationJobs -bxor
        #[Microsoft.SqlServer.Replication.ScriptOptions]::IncludeCreateLogreaderAgent -bxor
        #[Microsoft.SqlServer.Replication.ScriptOptions]::IncludeCreateQueuereaderAgent  -bxor
        #[Microsoft.SqlServer.Replication.ScriptOptions]::IncludePublisherSideSubscriptions -bxor

        $publication_object.Script($script_val)
    }

    Invoke-Command -ComputerName TravellerSQLCL -ScriptBlock $Script | Out-File $PublicationScript
<#
    foreach ($Location in $SDLCScriptCopy) {
        Copy-Item -Path $PublicationScript -Destination $Location
    }
#>    
}
