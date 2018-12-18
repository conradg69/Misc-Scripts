$SDLC = @{
    DatabaseName = 'TR4_DEV'
    Server       = 'WERCOVRDEVSQLD1'
    FusionILTCacheSearch = 'FusionILTCacheSearchDEV'
}

$DropReplicationScript = @"
EXEC sp_dropsubscription 
  @publication = N'pubFusionILTCache', 
  @article = N'all',
  @subscriber = 'WERCOVRDEVSQLD1';
GO

-- Remove a transactional publication.
EXEC sp_droppublication @publication = N'pubFusionILTCache';
"@

$SubscriptionScript = @"
exec sp_addsubscription @publication = N'pubFusionILTCache', @subscriber = N'WERCOVRDEVSQLD1', 
@destination_db = N'FusionILTCacheSearchDEV', @subscription_type = N'Push', @sync_type = N'automatic', 
@article = N'all', @update_mode = N'read only', @subscriber_type = 0

exec sp_addpushsubscription_agent @publication = N'pubFusionILTCache', @subscriber = N'WERCOVRDEVSQLD1', 
@subscriber_db = N'FusionILTCacheSearchDEV', @job_login = null, @job_password = null, @subscriber_security_mode = 1, 
@frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, 
@frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, 
@active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
"@


$ILTBookingTableIndex = @"
CREATE NONCLUSTERED INDEX [IDXC_QuoteID_SID] ON [dbo].[Booking] 
(
	[QuoteID] ASC,
	[SID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
"@

$ReplicationScript = '\\VLOPVRSTOAPP01\SQL_Backups_Traveller\TravellerScriptedObjects\Replication\Modified_TR4_Dev\TR4Dev_ILT_ReplicationExport.sql'

#Drop the Current replication. Pulication and Subscribers
Invoke-DbaSqlQuery -SqlInstance $SDLC.Server -Database $SDLC.DatabaseName -Query $DropReplicationScript -Verbose

#Add Replication Publisher
Invoke-DbaSqlQuery -SqlInstance $SDLC.Server -Database $SDLC.DatabaseName -File $ReplicationScript -Verbose

#Add Subscriber
Invoke-DbaSqlQuery -SqlInstance $SDLC.Server -Database $SDLC.DatabaseName -Query $SubscriptionScript -Verbose

#Get Name of the Publication
$publication = Get-DbaRepPublication -SqlInstance WERCOVRDEVSQLD1 
$PubName = $publication.PublicationName

#Start the Snapshot Agent
$SQLJobs = Get-DbaAgentJob -SqlInstance WERCOVRDEVSQLD1 -Verbose | Where-Object {($_.Category -eq "REPL-Snapshot" -and $_.Name -like "*$PubName*")} 
Start-DbaAgentJob -SqlInstance WERCOVRDEVSQLD1 -Job $SQLJobs.name -Verbose

#Apply ILT Index
Invoke-DbaSqlQuery -SqlInstance $SDLC.Server -Database $SDLC.FusionILTCacheSearch -Query $ILTBookingTableIndex -Verbose
