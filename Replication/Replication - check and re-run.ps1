Import-Module dbatools;

#$LondonILTServers = 'PH272708', 'PH272808', 'PH272908', 'PH272908', 'PH302108', 'PH302208', 'PH347608', 'PH347708', 'PH347808', 'PH508008', 'PH509608', 'PH521908'

#Get all the Replication Distibution jobs except the StaticAvailability. Restart any idle jobs
$SQLJobs = Get-DbaAgentJob -SqlInstance CP472808SQL -Verbose | Where-Object {($_.Category -eq "REPL-Distribution" -and $_.Name -notlike "*StaticAvailability*")}
    foreach($RepJob in $SQLJobs)
    {
        if ($RepJob.CurrentRunStatus -eq "Idle")
        {
            Start-DbaAgentJob -SqlInstance $RepJob.ComputerName -Job $RepJob.Name
            write-host "Job Started - $RepJob.Name"
            $RepJob | Select-Object {Get-Date -Format g} , 'OriginatingServer', 'Name','CurrentRunStatus','LastRunDate','LastRunOutcome','DateCreated','DateLastModified' | 
                Write-DbaDataTable -SqlInstance CP472808SQL -Database DBAdmin -Table PS_ReplicationMonitor -AutoCreateTable -Verbose
        }
    }
