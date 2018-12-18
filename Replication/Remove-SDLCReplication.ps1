Function Remove-SDLCReplication {

    $SDLCServer = 'WERCOVRDEVSQLD1'
    $SDLCDatabase = 'TR4_DEV'
    $PublicationName = 'pubFusionILTCache'

    $DropReplicationScript = @"
    EXEC sp_dropsubscription 
    @publication = N'$PublicationName', 
    @article = N'all',
    @subscriber = '$SDLCServer';
    GO

    -- Remove a transactional publication.
    EXEC sp_droppublication @publication = N'$PublicationName';
"@

    If (((Get-DbaRepPublication -SqlInstance $SDLCServer -Database $SDLCDatabase).PublicationName) -eq $PublicationName) {

        #Check then Drop the Current replication. Pulication and Subscribers
        Invoke-DbaQuery -SqlInstance $SDLCServer -Database $SDLCDatabase -Query $DropReplicationScript -Verbose
    }

}