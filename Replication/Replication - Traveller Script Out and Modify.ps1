Function Get-ScriptOutTravellerReplication {

    $Script = {

        $servername = 'TravellerSQLCL'
        $databasename = 'TR4_LIVE'
        $publication_name = 'pubFusionILTCache'
        $ScriptOutputFolder = 'C:\Temp\FileCopy\'
        $FileName = 'Traveller_ILT_ReplicationExport.sql'


        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Rmo") |Out-Null
        $repserver = New-Object "Microsoft.SqlServer.Replication.ReplicationServer"
        $srv = New-Object "Microsoft.SqlServer.Management.Common.ServerConnection" $servername
        $srv.connect()
        $repserver.ConnectionContext = $srv
        $repdb = $repserver.ReplicationDatabases[$databasename]
        $publication_object = $repdb.transpublications[$publication_name]
    
        #$publication_object.TransArticles

        $script_val = [Microsoft.SqlServer.Replication.ScriptOptions]::Creation -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludeEnableReplicationDB -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludeCreateSnapshotAgent   -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludePublications -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludePublicationAccesses -bxor
        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludeArticles -bxor

        #[Microsoft.SqlServer.Replication.ScriptOptions]::IncludeAll  -bxor
        #[Microsoft.SqlServer.Replication.ScriptOptions]::IncludeReplicationJobs -bxor
        #[Microsoft.SqlServer.Replication.ScriptOptions]::IncludeCreateLogreaderAgent -bxor
        #[Microsoft.SqlServer.Replication.ScriptOptions]::IncludeCreateQueuereaderAgent  -bxor
        #[Microsoft.SqlServer.Replication.ScriptOptions]::IncludePublisherSideSubscriptions -bxor

        [Microsoft.SqlServer.Replication.ScriptOptions]::IncludeGo

        $publication_object.Script($script_val)
    }

    Invoke-Command -ComputerName TravellerSQLCL -ScriptBlock $Script | Out-File "$ScriptOutputFolder$FileName"

}

<#
| Out-File \\VLOPVRSTOAPP01\SQL_Backups_Traveller\TravellerScriptedObjects\Replication\Traveller_ILT_ReplicationExport.sql



    if ( -Not (Test-Path -Path $ModifiedScriptFolder ) ) {
    New-Item -ItemType directory -Path $ModifiedScriptFolder
}


$Source = '\\VLOPVRSTOAPP01\SQL_Backups_Traveller\TravellerScriptedObjects\Replication\Traveller_ILT_ReplicationExport.sql'
$ModifiedScript = "$ModifiedScriptFolder\TR4Dev_ILT_ReplicationExport.sql"

#Dir -Path $Source -File -Recurse | Copy-Item -Destination $Source 
(Get-Content $Source).Replace("TR4_LIVE", "TR4_DEV") | Set-Content $ModifiedScript 
(Get-Content $ModifiedScript).Replace("vrguk\ProdSQLServer", "VRGUK\SQL_DBA (Earby)") | Set-Content $ModifiedScript 
(Get-Content $ModifiedScript).Replace("VRGUK\ProdSQLServerAgent", "VRGUK\SQL_DBA (Earby)") | Set-Content $ModifiedScript
(Get-Content $ModifiedScript).Replace("VRGUK\ProdTRAVSQLAgentServ", "VRGUK\SQL_DBA (Earby)") | Set-Content $ModifiedScript
#>


