Function Add-SDLCReplication {

    $SDLCServer = 'WERCOVRDEVSQLD1'
    $SDLCDatabase = 'TR4_DEV'
    $SDCLScriptLocation = '\\Wercovrdevsqld1\dba\EnvironmentRefresh\DEV\Replication\SDLCCopy'
    $PublicationName = 'pubFusionILTCache'

    $ReplicationScript = (Get-ChildItem -Path $SDCLScriptLocation -Recurse -Include *.sql |
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1).FullName

    If (((Get-DbaRepPublication -SqlInstance $SDLCServer -Database $SDLCDatabase).PublicationName) -ne $PublicationName) {
        #Check then Add Publication
        Invoke-DbaQuery -SqlInstance $SDLCServer -Database $SDLCDatabase -File $ReplicationScript -Verbose
    }

}





