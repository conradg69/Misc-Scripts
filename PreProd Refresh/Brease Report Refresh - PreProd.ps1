$reportServerUriLive = 'http://thgdocuments/Reportserver'
$reportServerUriDest = 'http://wercovruatsqld1/Reportserver'
$RootFolderPath = "/"
$RootBackupFolderName = 'BreaseReportBackups'
$RootBackupFolderPath = "$RootFolderPath$RootBackupFolderName"
$BreasePreProdFolder = 'TR4_PreProd'
$BreasePreProdFolderSSRS = 'Brease_PreProd'
$CurrentDateTime = Get-Date -Format FileDateTime 
$DateTimeFormatted = $CurrentDateTime.Substring(0,13)
$PreProdBackupFolder = "$BreasePreProdFolder-$DateTimeFormatted"
$DetailReportsFolder = "Detail Reports"
$SelectorReportsFolder = "Selector Reports"
$downloadFolderDetailReports = "H:\SSRSBackupRefresh\ReportBackups\TR4_PreProd\$DetailReportsFolder $DateTimeFormatted"
$downloadFolderSelectorReports = "H:\SSRSBackupRefresh\ReportBackups\TR4_PreProd\Selector Reports $DateTimeFormatted"
$downloadFolderLiveDetailReports = "H:\SSRSBackupRefresh\ReportBackups\TR4_PreProd\Live $DetailReportsFolder $DateTimeFormatted"
$downloadFolderLiveSelectorReports = "H:\SSRSBackupRefresh\ReportBackups\TR4_PreProd\Live $SelectorReportsFolder $DateTimeFormatted"
$DataSourcePath2 = "/Brease_PreProd/Data Sources/BreasePreProd"
$TR4_PreProdRootFolder = 'H:\SSRSBackupRefresh\ReportBackups\TR4_PreProd'
#$BreaseQAEFolderSSRS = 'Brease_FinanceQAE'

#Create Brease  Folders for the RDL files
New-Item -Path $downloadFolderDetailReports -ItemType directory 
New-Item -Path $downloadFolderSelectorReports -ItemType directory 
New-Item -Path $downloadFolderLiveDetailReports -ItemType directory
New-Item -Path $downloadFolderLiveSelectorReports -ItemType directory

write-host 'Downloading Detail Reports'
#Download all Detail Report RDL files to a Folder 
Get-RsFolderContent -ReportServerUri $reportServerUriDest -RsFolder "$RootFolderPath$BreasePreProdFolderSSRS/$DetailReportsFolder" |  Where-Object TypeName -eq 'Report' |
    Select-Object -ExpandProperty Path |
    Out-RsCatalogItem -ReportServerUri $reportServerUriDest -Destination $downloadFolderDetailReports 

write-host 'Downloading Selector Reports'
#Download all Selector Report RDL files to a Folder 
Get-RsFolderContent -ReportServerUri $reportServerUriDest -RsFolder "$RootFolderPath$BreasePreProdFolderSSRS/$SelectorReportsFolder" |  Where-Object TypeName -eq 'Report' |
    Select-Object -ExpandProperty Path |
    Out-RsCatalogItem -ReportServerUri $reportServerUriDest -Destination $downloadFolderSelectorReports

write-host 'Downloading Live Detail Reports'
#Download all Live Detail Report RDL files to a Folder 
Get-RsFolderContent -ReportServerUri $reportServerUriLive -RsFolder "/Brease/$DetailReportsFolder" |  Where-Object TypeName -eq 'Report' |
    Select-Object -ExpandProperty Path |
    Out-RsCatalogItem -ReportServerUri $reportServerUriLive -Destination $downloadFolderLiveDetailReports

write-host 'Downloading Live Selector Reports'
#Download all Selector Report RDL files to a Folder 
Get-RsFolderContent -ReportServerUri $reportServerUriLive -RsFolder "/Brease/$SelectorReportsFolder" |  Where-Object TypeName -eq 'Report' |
    Select-Object -ExpandProperty Path |
    Out-RsCatalogItem -ReportServerUri $reportServerUriLive -Destination $downloadFolderLiveSelectorReports

#Remove Reports that need to be manually uploaded to the a separate folder
Get-ChildItem -Path $downloadFolderLiveDetailReports  -Recurse -Filter "*[*" | Remove-Item
Get-ChildItem -Path $downloadFolderLiveDetailReports  -Recurse -Filter "*WebAppsTest*" | Remove-Item
Get-ChildItem -Path $downloadFolderDetailReports  -Recurse -Filter "*[*" | Remove-Item
Get-ChildItem -Path $downloadFolderDetailReports  -Recurse -Filter "*WebAppsTest*" | Remove-Item

#Remove-RsCatalogItem -ReportServerUri $reportServerUriDest -RsItem "$RootFolderPath$BreaseQAEFolderSSRS/$SelectorReportsFolder" -Confirm:$false 
#Remove-RsCatalogItem -ReportServerUri $reportServerUriDest -RsItem "$RootFolderPath$BreaseQAEFolderSSRS/$DetailReportsFolder" -Confirm:$false 

write-host 'Creating SSRS Folders'
#create SSRS Folders
New-RsFolder -ReportServerUri $reportServerUriDest -RsFolder $RootBackupFolderPath -FolderName $PreProdBackupFolder
New-RsFolder -ReportServerUri $reportServerUriDest -RsFolder "$RootBackupFolderPath/$PreProdBackupFolder" -FolderName $DetailReportsFolder
New-RsFolder -ReportServerUri $reportServerUriDest -RsFolder "$RootBackupFolderPath/$PreProdBackupFolder" -FolderName $SelectorReportsFolder
#New-RsFolder -ReportServerUri $reportServerUriDest -RsFolder $RootFolderPath -FolderName $BreaseQAEFolderSSRS
#New-RsFolder -ReportServerUri $reportServerUriDest -RsFolder "$RootFolderPath$BreasePreProdFolderSSRS" -FolderName $DetailReportsFolder
#New-RsFolder -ReportServerUri $reportServerUriDest -RsFolder "$RootFolderPath$BreasePreProdFolderSSRS" -FolderName $SelectorReportsFolder

write-host 'Uploading Detail Reports - Backups'
#Upload all Detail Reports from the download folder
Write-RsFolderContent -ReportServerUri $reportServerUriDest -Path $downloadFolderDetailReports -RsFolder "$RootBackupFolderPath/$PreProdBackupFolder/$DetailReportsFolder" -Overwrite

write-host 'Uploading Selector Reports - Backups'
#Upload all Selector Reports from the download folder
Write-RsFolderContent -ReportServerUri $reportServerUriDest -Path $downloadFolderSelectorReports -RsFolder "$RootBackupFolderPath/$PreProdBackupFolder/$SelectorReportsFolder" -Overwrite
<#
write-host 'Uploading Detail Reports - Live Copy'
#Upload all Live Detail Reports from the download folder
Write-RsFolderContent -ReportServerUri $reportServerUriDest -Path $downloadFolderLiveDetailReports -RsFolder "$RootFolderPath$BreasePreProdFolderSSRS/$DetailReportsFolder" -Overwrite

write-host 'Uploading Selector Reports - Live Copy'
#Upload all Selector Reports from the download folder
Write-RsFolderContent -ReportServerUri $reportServerUriDest -Path $downloadFolderLiveSelectorReports -RsFolder "$RootFolderPath$BreasePreProdFolderSSRS/$SelectorReportsFolder" -Overwrite
#>
#Clean Up - moved RDL's folder to a New folder
New-Item -Path "$TR4_PreProdRootFolder/ReportBackups $DateTimeFormatted" -ItemType directory
Move-Item -Path $downloadFolderDetailReports -Destination "$TR4_PreProdRootFolder/ReportBackups $DateTimeFormatted"
Move-Item -Path $downloadFolderSelectorReports -Destination "$TR4_PreProdRootFolder/ReportBackups $DateTimeFormatted"
Move-Item -Path $downloadFolderLiveDetailReports -Destination "$TR4_PreProdRootFolder/ReportBackups $DateTimeFormatted"
Move-Item -Path $downloadFolderLiveSelectorReports -Destination "$TR4_PreProdRootFolder/ReportBackups $DateTimeFormatted"

write-host 'Updating DataSourses - Backed Up Selector Reports'
$BackedUpSelectorReports = Get-RsCatalogItems -ReportServerUri $reportServerUriDest -RsFolder "$RootBackupFolderPath/$PreProdBackupFolder/$SelectorReportsFolder"
# Set report datasource
$BackedUpSelectorReports | Where-Object TypeName -eq 'Report' | ForEach-Object {
    $dataSource = Get-RsItemDataSource -ReportServerUri $reportServerUriDest -RsItem $_.Path
    if ($dataSource -ne $null) {
        Set-RsDataSourceReference -ReportServerUri $reportServerUriDest -Path $_.Path -DataSourceName $dataSource.Name -DataSourcePath $DataSourcePath2
        Write-Output "Changed datasource $($dataSource.Name) set to $DataSourcePath2 on report $($_.Path) "
    }
    else {
        Write-Warning "Report $($_.Path) does not contain an datasource"
    }
}

write-host 'Updating DataSourses - Backed Up Detail Reports'
$BackedUpDetailReports = Get-RsCatalogItems -ReportServerUri $reportServerUriDest -RsFolder "$RootBackupFolderPath/$PreProdBackupFolder/$DetailReportsFolder"
# Set report datasource
$BackedUpDetailReports | Where-Object TypeName -eq 'Report' | ForEach-Object {
    $dataSource = Get-RsItemDataSource -ReportServerUri $reportServerUriDest -RsItem $_.Path
    if ($dataSource -ne $null) {
        Set-RsDataSourceReference -ReportServerUri $reportServerUriDest -Path $_.Path -DataSourceName $dataSource.Name -DataSourcePath $DataSourcePath2
        Write-Output "Changed datasource $($dataSource.Name) set to $DataSourcePath2 on report $($_.Path) "
    }
    else {
        Write-Warning "Report $($_.Path) does not contain an datasource"
    }
}

write-host 'Updating DataSourses - Live Detail Reports'

$BackedUpLiveDetailReports = Get-RsCatalogItems -ReportServerUri $reportServerUriDest -RsFolder "$RootFolderPath$BreasePreProdFolderSSRS/$DetailReportsFolder"
# Set report datasource
$BackedUpLiveDetailReports | Where-Object TypeName -eq 'Report' | ForEach-Object {
    $dataSource = Get-RsItemDataSource -ReportServerUri $reportServerUriDest -RsItem $_.Path
    if ($dataSource -ne $null) {
        Set-RsDataSourceReference -ReportServerUri $reportServerUriDest -Path $_.Path -DataSourceName $dataSource.Name -DataSourcePath $DataSourcePath2
        Write-Output "Changed datasource $($dataSource.Name) set to $DataSourcePath2 on report $($_.Path) "
    }
    else {
        Write-Warning "Report $($_.Path) does not contain an datasource"
    }
}

write-host 'Updating DataSourses - Live Selector Reports'

$BackedUpSelectorReports = Get-RsCatalogItems -ReportServerUri $reportServerUriDest -RsFolder "$RootFolderPath$BreasePreProdFolderSSRS/$SelectorReportsFolder"
# Set report datasource
$BackedUpSelectorReports | Where-Object TypeName -eq 'Report' | ForEach-Object {
    $dataSource = Get-RsItemDataSource -ReportServerUri $reportServerUriDest -RsItem $_.Path
    if ($dataSource -ne $null) {
        Set-RsDataSourceReference -ReportServerUri $reportServerUriDest -Path $_.Path -DataSourceName $dataSource.Name -DataSourcePath $DataSourcePath2
        Write-Output "Changed datasource $($dataSource.Name) set to $DataSourcePath2 on report $($_.Path) "
    }
    else {
        Write-Warning "Report $($_.Path) does not contain an datasource"
    }
}