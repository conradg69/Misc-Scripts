#Set-Location F:\DSC\


Configuration SQLInstall
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackagePath
       
    )
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName SQLServer
    Import-DSCResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName SqlServerDsc
    
    Node $AllNodes.where({ $_.Role -eq "SQLENGINE" }).NodeName 
    {
        
        $SSMS = $ConfigurationData.SSMSConfig
        $SQLISOFile = $ConfigurationData.SQLISOFile
        $SQLInstallConfig = $ConfigurationData.SQLInstallConfig
        $DBADatabase = $ConfigurationData.DBADatabases
        $DatabaseMail = $ConfigurationData.DatabaseMailConfig
        $SetupScripts = $ConfigurationData.DBASetupScripts

        #copy SSMS exe to all servers
         File CopySSMSInstallFileToServer
        {
            SourcePath = $SSMS.PathSource
            DestinationPath = $SSMS.PathDestination
            Type = "File"
            Ensure = "Present"
        }

        File TransferSQLServerIso2016ToServer
        {
            SourcePath =  $SQLISOFile.PathSource
            DestinationPath = $SQLISOFile.PathDestination
            Type = "File"
            Ensure = "Present"
        }

        File TransferDBASetupFilesToServer
        {
            SourcePath =  $SetupScripts.PathSource
            DestinationPath = $SetupScripts.PathDestination
            Type = "Directory"
            Recurse = $true
            Ensure = "Present"
        }

        Script CopySQLInstallFilesToLocalFolder
        {
            GetScript =
            {
                $PathCheck = Test-Path -Path C:\SQLSetup\SQL2016\
                
                $vals = @{
                    Exist = $PathCheck;
                    
                }
                $vals
            }
            SetScript =
            {
                
                $script = 
                {
                $setupDriveLetter = (Mount-DiskImage -ImagePath C:\SQLSetup\SQLInstall\SQLServer2016.iso -PassThru | Get-Volume).DriveLetter + ":\"
                if ($setupDriveLetter -eq $null) {
                throw "Could not mount SQL install iso"
                                                }
                 Copy-item -Force -Recurse -Verbose $setupDriveLetter -Destination C:\SQLSetup\SQL2016\
                 #dismount the iso
                 Dismount-DiskImage -ImagePath C:\SQLSetup\SQLInstall\SQLServer2016.iso
                 }
                    Invoke-Command -ComputerName localhost -ScriptBlock $script
            }
            TestScript =
            {
                $PathCheck = Test-Path -Path C:\SQLSetup\SQL2016\
                
                $res = $PathCheck
                if ($res) {
                    Write-Verbose "Folder already created"
                } else {
                    Write-Verbose "Folder not created"
                }
                $res
            }
            DependsOn = "[File]TransferSQLServerIso2016ToServer"
        }
                
        SqlSetup InstallSQLInstance
        {
           InstanceName = $SQLInstallConfig.InstanceName
           Features = $SQLInstallConfig.Features
           SourcePath = $SQLInstallConfig.SourcePath
           SQLSysAdminAccounts = @('Administrators')
           InstanceDir = $SQLInstallConfig.InstanceDir
           InstallSQLDataDir = $SQLInstallConfig.InstallSQLDataDir
           InstallSharedDir = $SQLInstallConfig.InstallSharedDir
           InstallSharedWOWDir = $SQLInstallConfig.InstallSharedWOWDir
           SQLTempDBDir = $SQLInstallConfig.SQLTempDBDir
           SQLTempDBLogDir = $SQLInstallConfig.SQLTempDBLogDir
           SQLUserDBDir = $SQLInstallConfig.SQLUserDBDir
           SQLUserDBLogDir = $SQLInstallConfig.SQLUserDBLogDir
           SQLCollation = $SQLInstallConfig.SQLCollation
           #SecurityMode = $SQLInstallConfig.SecurityMode
           DependsOn = '[Script]CopySQLInstallFilesToLocalFolder'
            
        }

        SqlServerNetwork EnableTCP
        {
            InstanceName = $SQLInstallConfig.InstanceName
            ProtocolName = 'Tcp'
            IsEnabled = $SQLInstallConfig.TCPEnabledStatus
            ServerName = $Node.ServerName
            RestartService = $true
            TcpPort = $SQLInstallConfig.TcpPort   
            DependsOn = '[SqlSetup]InstallSQLInstance'  
        }
       
        Package InstallSSMS
        {
            Name = $SSMS.FileName
            Path = $SSMS.PathDestination
            ProductId = $SSMS.ProductID
            Ensure =  "Present"
            Arguments = "/install /passive /restart"
    
        }
            
        Script EnableNamedPipes
        {
            GetScript =
            {
                
                $ServerName =$env:COMPUTERNAME
                $smo = 'Microsoft.SqlServer.Management.Smo.'  
                $wmi = new-object ($smo + 'Wmi.ManagedComputer').  
                $uri = "ManagedComputer[@Name= '$ServerName']/ ServerInstance[@Name='MSSQLSERVER']/ServerProtocol[@Name='np']"  
                $np = $wmi.GetSmoObject($uri)  
                $Result = $np.IsEnabled
                $Result
            }
            SetScript =
            {
                
                $ServerName =$env:COMPUTERNAME
                $smo = 'Microsoft.SqlServer.Management.Smo.'  
                $wmi = new-object ($smo + 'Wmi.ManagedComputer').  
                $uri = "ManagedComputer[@Name= '$ServerName']/ ServerInstance[@Name='MSSQLSERVER']/ServerProtocol[@Name='np']"  
                $np = $wmi.GetSmoObject($uri) 
                $np.IsEnabled = $true  
                $np.Alter()  
                
            }
            TestScript =
            {
                $ServerName =$env:COMPUTERNAME
                $smo = 'Microsoft.SqlServer.Management.Smo.'  
                $wmi = new-object ($smo + 'Wmi.ManagedComputer').  
                $uri = "ManagedComputer[@Name= '$ServerName']/ ServerInstance[@Name='MSSQLSERVER']/ServerProtocol[@Name='np']"  
                $np = $wmi.GetSmoObject($uri)  
                $Result = $np.IsEnabled
                $Result
                if ($Result) {
                    Write-Verbose "Named Pipes already enabled"
                } else {
                    Write-Verbose "Named Pipes not enabled"
                }
                $Result
            }
            DependsOn = "[SqlSetup]InstallSQLInstance"

         }
   
        SqlDatabase DBAdmin
        {
            InstanceName = $SQLInstallConfig.InstanceName
            Name = $DBADatabase.DBAdmin
            ServerName = $Node.ServerName
            DependsOn = '[SqlSetup]InstallSQLInstance'
            Ensure = ‘Present’
        }

        SqlDatabase DBAToolKit
        {
            InstanceName = $SQLInstallConfig.InstanceName
            Name = $DBADatabase.DBAToolKit
            ServerName = $Node.ServerName
            DependsOn = '[SqlSetup]InstallSQLInstance'
            Ensure = ‘Present’
    
        }

        Script SetAuthentionMode
        {
            GetScript =
            {
                
                $instanceName = "localhost"
                $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName 
                $Result = $server.settings.LoginMode
                $Result = ($server.settings.LoginMode -eq 'MIXED') 
                $Result
            }
            SetScript =
            {
                $instanceName = "localhost"
                $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName
                $server.settings.LoginMode ='MIXED'
                $server.settings.Alter()   
            }
            TestScript =
            {
                $instanceName = "localhost"
                $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName 
                $Result = $server.settings.LoginMode
                $Result = ($server.settings.LoginMode -eq 'MIXED') 
                $Result
                if ($Result) {
                    Write-Verbose "Authentication is already set to MIXED Mode"
                } else {
                    Write-Verbose "Authentication being set to MIXED Mode"
                }
                $Result
            }
            DependsOn = "[SqlSetup]InstallSQLInstance"


        }

        SqlServerMemory SetSQLMemory
        {
            InstanceName = $SQLInstallConfig.InstanceName
            Ensure = 'Present'
            MaxMemory = $Node.MaxMemory
            MinMemory = $Node.MinMemory
            ServerName = $Node.ServerName
            DependsOn = '[SqlSetup]InstallSQLInstance'
        }
        
        SqlServerConfiguration EnableDatabaseMail
        {
            InstanceName = $SQLInstallConfig.InstanceName
            OptionName = 'Database Mail XPs'
            OptionValue = '1'
            ServerName = $Node.ServerName
            DependsOn = '[SqlSetup]InstallSQLInstance'
            RestartService = 1
            
        }

        SqlServerDatabaseMail SetupDatabaseMail
        {
            AccountName  = $DatabaseMail.AccountName
            EmailAddress = $DatabaseMail.EmailAddress
            InstanceName = $SQLInstallConfig.InstanceName
            MailServerName = $DatabaseMail.MailServerName
            ProfileName = $DatabaseMail.ProfileName
            Description = $DatabaseMail.Description
            DisplayName = $Node.DatabaseMailDisplayName
            Ensure = 'Present'
            ReplyToAddress = $DatabaseMail.ReplyToAddress
            ServerName = $Node.ServerName
            TcpPort = $DatabaseMail.TcpPort
            DependsOn = '[SqlServerConfiguration]EnableDatabaseMail'
        }
        
        Script Add_sp_WhoIsActiveToDBADatabase
        {
            GetScript =
            { 
                $Procedures = Get-DbaDbStoredProcedure -SqlInstance localhost -Database DBAToolKit -ExcludeSystemSp
                $Result =  ($Procedures.Name | where {$_ -eq 'sp_WhoIsActive'}) -eq 'sp_WhoIsActive';
                $Result
            }
            SetScript =
            {
                 Install-DbaWhoIsActive -SqlInstance localhost -Database DBAToolKit -LocalFile 'C:\SQLSetup\Scripts\who_is_active_v11_32.zip'    
            }
            TestScript =
            {
                $Procedures = Get-DbaDbStoredProcedure -SqlInstance localhost -Database DBAToolKit -ExcludeSystemSp
                $result = ($Procedures.Name | where {$_ -eq 'sp_WhoIsActive'}) -eq 'sp_WhoIsActive';
                if ($result) {
                    Write-Verbose "sp_WhoIsActive already available"
                    } else {
                    Write-Verbose "sp_WhoIsActive not in DBAToolkit DB - Creating"
                }
                $result
            }
            
        }

        Script InstallMaintenanceSolution
        {
            GetScript =
            { 
                $Procedures = Get-DbaDbStoredProcedure -SqlInstance localhost -Database DBAToolKit -ExcludeSystemSp
                $Result =  ($Procedures.Name | where {$_ -eq 'CommandExecute'}) -eq 'CommandExecute';
                $Result
            }
            SetScript =
            {
                 Install-DbaMaintenanceSolution -SqlInstance localhost -Database DBAToolkit -BackupLocation "C:\SQLBackups" -CleanupTime 72 -ReplaceExisting -localFile C:\SQLSetup\Scripts\MaintenanceSolution.zip -LogToTable -InstallJobs -OutputFileDirectory "C:\SQLBackups" -Solution All    
            }
            TestScript =
            {
                $Procedures = Get-DbaDbStoredProcedure -SqlInstance localhost -Database DBAToolKit -ExcludeSystemSp
                $result = ($Procedures.Name | where {$_ -eq 'CommandExecute'}) -eq 'CommandExecute';
                if ($result) {
                    Write-Verbose "MaintenanceSolution already available"
                    } else {
                    Write-Verbose "MaintenanceSolution not in DBAToolkit DB - Creating"
                }
                $result
            }
            
        }

        Script InstallFirstResponderKit
        {
            GetScript =
            { 

                $Result = ((Get-DbaDbStoredProcedure -SqlInstance localhost -Database DBAToolKit -ExcludeSystemSp).name | 
                where {($_ -like 'sp_Blitz*') -or ($_ -like 'sp_AllNight*') -or ($_ -eq 'sp_foreachdb') -or ($_ -eq 'sp_DatabaseRestore')}).count -eq 11

                $Result
            }
            SetScript =
            {
                 Install-DbaFirstResponderKit -SqlInstance localhost -Database DBAToolKit -LocalFile C:\SQLSetup\Scripts\FirstResponderKit.zip   
            }
            TestScript =
            {

                $result = ((Get-DbaDbStoredProcedure -SqlInstance localhost -Database DBAToolKit -ExcludeSystemSp).name | 
                where {($_ -like 'sp_Blitz*') -or ($_ -like 'sp_AllNight*') -or ($_ -eq 'sp_foreachdb') -or ($_ -eq 'sp_DatabaseRestore')}).count -eq 11

                if ($result) {
                    Write-Verbose "FirstResponderKit already installed"
                    } else {
                    Write-Verbose "FirstResponderKit not installed"
                }
                $result
            }
            
        }

        

        Script InstallSQLWATCHPerformanceMonitor
        {
            GetScript =
            { 

                $Result = ((Get-DbaDbTable -SqlInstance localhost -Database DBAdmin).Name | 
                            where {($_ -like '*sql_perf_mon*') -or ($_ -like 'logger_*')}).count -eq 22

                $Result
            }
            SetScript =
            {
                 Install-DbaSqlWatch -SqlInstance localhost -Database DBAdmin -LocalFile 'C:\SQLSetup\Scripts\SQLWATCH_1.3.20.zip'  
            }
            TestScript =
            {

                $Result = ((Get-DbaDbTable -SqlInstance localhost -Database DBAdmin).Name | 
                            where {($_ -like '*sql_perf_mon*') -or ($_ -like 'logger_*')}).count -eq 22

                if ($result) {
                    Write-Verbose "SQLWatch already installed"
                    } else {
                    Write-Verbose "SQLWatch not installed"
                }
                $result
            }
            
        }
 
        
 
 <# 
 
         
        

        Script AddDBAOperator
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentOperator -SqlInstance Lonpesssql01 | where {$_.EmailAddress -eq 'ssiowerdba@wyndhamdn.com'}).EmailAddress -eq 'ssiowerdba@wyndhamdn.com'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_operator @name=N'SQL DBA', 
		                @enabled=1, 
		                @weekday_pager_start_time=90000, 
		                @weekday_pager_end_time=180000, 
		                @saturday_pager_start_time=90000, 
		                @saturday_pager_end_time=180000, 
		                @sunday_pager_start_time=90000, 
		                @sunday_pager_end_time=180000, 
		                @pager_days=0, 
		                @email_address=N'ssiowerdba@wyndhamdn.com', 
		                @category_name=N'[Uncategorized]'
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose
                 

            }
            TestScript =
            {

                $result = (Get-DbaAgentOperator -SqlInstance Lonpesssql01 | where {$_.EmailAddress -eq 'ssiowerdba@wyndhamdn.com'}).EmailAddress -eq 'ssiowerdba@wyndhamdn.com'

                if ($result) {
                    Write-Verbose "DBAOperator already added"
                    } else {
                    Write-Verbose "DBAOperator not on the SQl Instance"
                }
                $result
            }


            
        }

        Script AddAlert_RespondtoDEADLOCK_GRAPH
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq 'Respond to DEADLOCK_GRAPH'}).Name -eq 'Respond to DEADLOCK_GRAPH'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_alert @name=N'Respond to DEADLOCK_GRAPH', 
		                @message_id=0, 
		                @severity=0, 
		                @enabled=1, 
		                @delay_between_responses=0, 
		                @include_event_description_in=5, 
		                @category_name=N'[Uncategorized]', 
		                @wmi_namespace=N'\\.\root\Microsoft\SqlServer\ServerEvents\MSSQLServer', 
		                @wmi_query=N'SELECT * FROM DEADLOCK_GRAPH'
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose
                 

            }
            TestScript =
            {

                $result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq 'Respond to DEADLOCK_GRAPH'}).Name -eq 'Respond to DEADLOCK_GRAPH'

                if ($result) {
                    Write-Verbose "Respond to DEADLOCK_GRAPH Alert already added"
                    } else {
                    Write-Verbose "Respond to DEADLOCK_GRAPH Alert not on the SQl Instance"
                }
                $result
            
            }

    }

        Script AddAlert_025_HardwareError
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '025 - Hardware Error'}).Name -eq '025 - Hardware Error'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_alert @name=N'025 - Hardware Error', 
		                @message_id=0, 
		                @severity=25, 
		                @enabled=1, 
		                @delay_between_responses=3600, 
		                @include_event_description_in=1, 
		                @notification_message=N'----- >>> Some type of media failure has occurred - DBA PLEASE INVESTIGATE <<< -----', 
		                @category_name=N'[Uncategorized]' 
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose

            }
            TestScript =
            {

                $result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '025 - Hardware Error'}).Name -eq '025 - Hardware Error'

                if ($result) {
                    Write-Verbose "025 - Hardware Error Alert already added"
                    } else {
                    Write-Verbose "025 - Hardware Error Alert not on the SQl Instance"
                }
                $result
            
            }

    }

        Script AddAlert_024_HardwareError
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '024 - Hardware Error'}).Name -eq '024 - Hardware Error'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_alert @name=N'024 - Hardware Error', 
		                @message_id=0, 
		                @severity=24, 
		                @enabled=1, 
		                @delay_between_responses=3600, 
		                @include_event_description_in=1, 
		                @notification_message=N'----- >>> Some type of media failure has occurred - DBA PLEASE INVESTIGATE <<< -----', 
		                @category_name=N'[Uncategorized]'
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose

            }
            TestScript =
            {

                $result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '024 - Hardware Error'}).Name -eq '024 - Hardware Error'

                if ($result) {
                    Write-Verbose "024 - Hardware Error Alert already added"
                    } else {
                    Write-Verbose "024 - Hardware Error Alert not on the SQl Instance"
                }
                $result
            
            }

    }
        
        Script AddAlert_023_DatabaseIntegritySuspect
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '023 - Database Integrity Suspect'}).Name -eq '023 - Database Integrity Suspect'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_alert @name=N'023 - Database Integrity Suspect', 
		                @message_id=0, 
		                @severity=23, 
		                @enabled=1, 
		                @delay_between_responses=3600, 
		                @include_event_description_in=1, 
		                @notification_message=N'----- >>> Integrity of the entire database is in question - DBA PLEASE INVESTIGATE <<< -----', 
		                @category_name=N'[Uncategorized]'
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose

            }
            TestScript =
            {

                $result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '023 - Database Integrity Suspect'}).Name -eq '023 - Database Integrity Suspect'

                if ($result) {
                    Write-Verbose "023 - Database Integrity Suspect - Alert already added"
                    } else {
                    Write-Verbose "023 - Database Integrity Suspect - Alert not on the SQL Instance"
                }
                $result
            
            }

    }
        
        Script AddAlert_022_FatalErrorTableIntegritySuspect
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '022 - Fatal Error Table Integrity Suspect'}).Name -eq '022 - Fatal Error Table Integrity Suspect'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_alert @name=N'022 - Fatal Error Table Integrity Suspect', 
		                @message_id=0, 
		                @severity=22, 
		                @enabled=1, 
		                @delay_between_responses=3600, 
		                @include_event_description_in=1, 
		                @notification_message=N'----- >>> Index specified in the message has been damaged by a software or hardware problem - DBA PLEASE INVESTIGATE <<< -----', 
		                @category_name=N'[Uncategorized]'
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose

            }
            TestScript =
            {

                $result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '022 - Fatal Error Table Integrity Suspect'}).Name -eq '022 - Fatal Error Table Integrity Suspect'

                if ($result) {
                    Write-Verbose "022 - Fatal Error Table Integrity Suspect - Alert already added"
                    } else {
                    Write-Verbose "022 - Fatal Error Table Integrity Suspect - Alert not on the SQL Instance"
                }
                $result
            
            }

    }

        Script AddAlert_021_FatalErrorinDatabaseProcesses
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '021 - Fatal Error in Database processes'}).Name -eq '021 - Fatal Error in Database processes'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_alert @name=N'021 - Fatal Error in Database processes', 
		                @message_id=0, 
		                @severity=21, 
		                @enabled=1, 
		                @delay_between_responses=3600, 
		                @include_event_description_in=1, 
		                @notification_message=N'----- >>> Affects all processes in the current database - DBA PLEASE INVESTIGATE  <<< -----', 
		                @category_name=N'[Uncategorized]'
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose

            }
            TestScript =
            {

                $result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '021 - Fatal Error in Database processes'}).Name -eq '021 - Fatal Error in Database processes'

                if ($result) {
                    Write-Verbose "021 - Fatal Error in Database processes - Alert already added"
                    } else {
                    Write-Verbose "021 - Fatal Error in Database processes - Alert not on the SQL Instance"
                }
                $result
            
            }

    }

        Script AddAlert_020_FatalErrorinCurrentProcess
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '020 - Fatal Error in Current Process'}).Name -eq '020 - Fatal Error in Current Process'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_alert @name=N'020 - Fatal Error in Current Process', 
		                @message_id=0, 
		                @severity=20, 
		                @enabled=1, 
		                @delay_between_responses=3600, 
		                @include_event_description_in=1, 
		                @notification_message=N'----- >>> A statement has encountered a problem - DBA PLEASE INVESTIGATE <<< -----', 
		                @category_name=N'[Uncategorized]'
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose

            }
            TestScript =
            {

                $result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '020 - Fatal Error in Current Process'}).Name -eq '020 - Fatal Error in Current Process'

                if ($result) {
                    Write-Verbose "020 - Fatal Error in Current Process - Alert already added"
                    } else {
                    Write-Verbose "020 - Fatal Error in Current Process - Alert not on the SQL Instance"
                }
                $result
            
            }

    }

        Script AddAlert_019_FatalErrorinResource
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '019 - Fatal Error in Resource'}).Name -eq '019 - Fatal Error in Resource'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_alert @name=N'019 - Fatal Error in Resource', 
		                @message_id=0, 
		                @severity=19, 
		                @enabled=1, 
		                @delay_between_responses=3600, 
		                @include_event_description_in=1, 
		                @notification_message=N'----- >>> Some internal limit has been exceeded - DBA PLEASE INVESTIGATE <<< -----', 
		                @category_name=N'[Uncategorized]'
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose

            }
            TestScript =
            {

                $result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '019 - Fatal Error in Resource'}).Name -eq '019 - Fatal Error in Resource'

                if ($result) {
                    Write-Verbose "019 - Fatal Error in Resource - Alert already added"
                    } else {
                    Write-Verbose "019 - Fatal Error in Resource - Alert not on the SQL Instance"
                }
                $result
            
            }

    }

        Script AddAlert_018_NonFatalInternalError
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '018 - Non Fatal Internal Error'}).Name -eq '018 - Non Fatal Internal Error'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_alert @name=N'018 - Non Fatal Internal Error', 
		                @message_id=0, 
		                @severity=18, 
		                @enabled=1, 
		                @delay_between_responses=3600, 
		                @include_event_description_in=1, 
		                @notification_message=N'----- >>> Internal software problem - DBA PLEASE INVESTIGATE <<< -----', 
		                @category_name=N'[Uncategorized]'
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose

            }
            TestScript =
            {

                $result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '018 - Non Fatal Internal Error'}).Name -eq '018 - Non Fatal Internal Error'

                if ($result) {
                    Write-Verbose "018 - Non Fatal Internal Error - Alert already added"
                    } else {
                    Write-Verbose "018 - Non Fatal Internal Error - Alert not on the SQL Instance"
                }
                $result
            
            }

    }

        Script AddAlert_017_InsufficientResources
        {
            GetScript =
            { 

                $Result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '017 - Insufficient Resources'}).Name -eq '017 - Insufficient Resources'

                $Result
            }
            SetScript =
            {
                 $Script = @"
                        EXEC msdb.dbo.sp_add_alert @name=N'017 - Insufficient Resources', 
		                @message_id=0, 
		                @severity=17, 
		                @enabled=1, 
		                @delay_between_responses=3600, 
		                @include_event_description_in=1, 
		                @notification_message=N'----- >>> Resource issues - DBA PLEASE INVESTIGATE <<< -----', 
		                @category_name=N'[Uncategorized]'
"@
                        Invoke-Sqlcmd2 -ServerInstance lonpesssql01 -Database MSDB -Query $Script -Verbose

            }
            TestScript =
            {

                $result = (Get-DbaAgentAlert -SqlInstance lonpesssql01 |Where-Object {$_.Name -eq '017 - Insufficient Resources'}).Name -eq '017 - Insufficient Resources'

                if ($result) {
                    Write-Verbose "017 - Insufficient Resources - Alert already added"
                    } else {
                    Write-Verbose "017 - Insufficient Resources - Alert not on the SQL Instance"
                }
                $result
            
            }
       
    }
 #>


    }

    Node $AllNodes.where({ $_.Role -eq "ReportServer" }).NodeName 
    {

        $SSMS = $ConfigurationData.SSMSConfig
        $SQLISOFile = $ConfigurationData.SQLISOFile
        $SQLInstallConfig = $ConfigurationData.SQLInstallConfig
        $DBADatabase = $ConfigurationData.DBADatabases
        $DatabaseMail = $ConfigurationData.DatabaseMailConfig

        File CopySSMSInstallFileToServer
        {
            SourcePath = $SSMS.PathSource
            DestinationPath = $SSMS.PathDestination
            Type = "File"
            Ensure = "Present"
        }

        File TransferSQLServerIso2016ToServer
        {
            SourcePath =  $SQLISOFile.PathSource
            DestinationPath = $SQLISOFile.PathDestination
            Type = "File"
            Ensure = "Present"
        }

        Script CopySQLInstallFilesToLocalFolder
        {
            GetScript =
            {
                $PathCheck = Test-Path -Path C:\SQLSetup\SQL2016\
                
                $vals = @{
                    Exist = $PathCheck;
                    
                }
                $vals
            }
            SetScript =
            {
                
                $script = 
                {
                $setupDriveLetter = (Mount-DiskImage -ImagePath C:\SQLSetup\SQLInstall\SQLServer2016.iso -PassThru | Get-Volume).DriveLetter + ":\"
                if ($setupDriveLetter -eq $null) {
                throw "Could not mount SQL install iso"
                                                }
                 Copy-item -Force -Recurse -Verbose $setupDriveLetter -Destination C:\SQLSetup\SQL2016\
                 #dismount the iso
                 Dismount-DiskImage -ImagePath C:\SQLSetup\SQLInstall\SQLServer2016.iso
                 }
                    Invoke-Command -ComputerName localhost -ScriptBlock $script
            }
            TestScript =
            {
                $PathCheck = Test-Path -Path C:\SQLSetup\SQL2016\
                
                $res = $PathCheck
                if ($res) {
                    Write-Verbose "Folder already created"
                } else {
                    Write-Verbose "Folder not created"
                }
                $res
            }
            DependsOn = "[File]TransferSQLServerIso2016ToServer"
        }

        SqlSetup InstallSQLInstance
        {
           InstanceName = $SQLInstallConfig.InstanceName
           Features = $Node.Features
           SourcePath = $SQLInstallConfig.SourcePath
           SQLSysAdminAccounts = @('Administrators')
           InstanceDir = $SQLInstallConfig.InstanceDir
           InstallSQLDataDir = $SQLInstallConfig.InstallSQLDataDir
           InstallSharedDir = $SQLInstallConfig.InstallSharedDir
           InstallSharedWOWDir = $SQLInstallConfig.InstallSharedWOWDir
           DependsOn = '[Script]CopySQLInstallFilesToLocalFolder'
            
        }

      

    }



}

SQLInstall -ConfigurationData C:\SQLDSCInstall\SetupScripts\ServerConfiguration.psd1 -PackagePath "\\DC1\InstallMedia" -Verbose

Start-DscConfiguration -Path C:\SQLDSCInstall\SQLMofFiles\SQLInstall -Wait -Force -Verbose


