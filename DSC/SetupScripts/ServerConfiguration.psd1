
@{
    AllNodes =   
    @(
        @{
            NodeName = '*'
            PSDscAllowDomainUser = $true
            MofFiles = 'C:\SQLDSCInstall\SQLMofFiles'
            DSCMofFileFolder = 'C:\SQLDSCInstall\SQLMofFiles\DSCModules\'     
         }
           
        @{
           Nodename      = 'Client1'
           ServerName    = 'Client1'
           Role          = @('SQLENGINE')
           Features      = 'SQLENGINE,Replication'
           MaxMemory     = '3000'
           MinMemory     = '200'
           DatabaseMailDisplayName = 'DC NonProd Client1'
                                                                                                    
         } 

        
        @{
           Nodename = 'Client2'
           ServerName = 'Client2'
           Role          = @('SQLENGINE')
           Features = 'SQLENGINE,Replication'
           MaxMemory = '2000'
           MinMemory = '100'
           DatabaseMailDisplayName = 'DC NonProd Client2'
                                                                                                    
         } 
         <#
         @{
           Nodename = 'Client3'
           ServerName = 'Client3'
           Role          = @('ReportServer')
           Features = 'RS'                                                                                         
         } 
         #>
      )
  
  #SQL Management Studio
  SSMSConfig = @{

            FileName = 'SSMS-Setup-ENU'
            ProductID = '00BE2F31-85B3-414F-8BAD-01E24FB17541'
            PathSource = '\\DC1\InstallMedia\SSMS-Setup-ENU.exe'
            PathDestination = 'C:\SQLSetup\SQLInstall\SSMS-Setup-ENU.exe'

  }

  #SQL Server ISO File
  SQLISOFile = @{
  
    PathSource = '\\DC1\InstallMedia\SQLServer2016\en_sql_server_2016_developer_with_service_pack_2_x64_dvd_12194995.iso'
    PathDestination = 'C:\SQLSetup\SQLInstall\SQLServer2016.iso'

  }

   #SQL Server ISO File
  DBASetupScripts = @{
  
    PathSource = '\\DC1\InstallMedia\SetupScripts\'
    PathDestination = 'C:\SQLSetup\Scripts\'

  }

  #SQL Server Install Configuration
  SQLInstallConfig = @{
    
    InstanceName = 'MSSQLSERVER'
    SourcePath =  'C:\SQLSetup\SQL2016'
    Features = 'SQLENGINE,Replication'
    InstanceDir = 'C:\SqlInstance'
    InstallSQLDataDir = 'C:\SqlInstanceData'
    InstallSharedDir = 'C:\Program Files\Microsoft SQL Server'
    InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
    SQLTempDBDir = 'C:\SQLData'
    SQLTempDBLogDir = 'C:\SQLTLogs'
    SQLUserDBDir = 'C:\SQLData'
    SQLUserDBLogDir = 'C:\SQLTLogs'
    SQLCollation = 'SQL_Latin1_General_CP1_CI_AS'
    SecurityMode = 'SQL'
    TcpPort = 1433 
    TCPEnabledStatus = $True
    
  }

  #SQL Server ISO File
  DBADatabases = @{
  
    DBAdmin = 'DBAdmin'
    DBAToolkit = 'DBAToolkit'

  }

  DatabaseMailConfig = @{

    AccountName  = 'SQLAlerts'
    EmailAddress = 'SQLAlertsP@wyndhamDN.com'
    MailServerName = 'WEPCAS.vrguk.europe.int.rci.com'
    ProfileName = 'SQL Alerts'
    Description = 'DBA Team Email Notifications'
    Ensure = 'Present'
    ReplyToAddress = 'norepley@thehoseasonsgroup.com'
    TcpPort = 25
  
  }

}

