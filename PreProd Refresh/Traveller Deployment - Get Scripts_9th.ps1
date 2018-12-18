#Open Physical Folders
<#
invoke-item	'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180427\WUK.6690.30555\WUK.6690.30555'
invoke-item	'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180522\WUK.6716.19200'
invoke-item	'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180712\WUK.6766.20957\WUK.6766.20957'
invoke-item '\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180720\VRUKL.6775.21600'
invoke-item	'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180805\VRUKL.6787.27777'
invoke-item	'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180805\VRUKL.6788.30203\VRUKL.6788.30203'
invoke-item	'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180813\VRUKL.6794.31510'
invoke-item	'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180813\VRUKL.6796.22920'
invoke-item	'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180813\VRUKL.6799.22227'
invoke-item	'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180901\VRUKL.6815.26543'
invoke-item	'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180901\VRUKL.6816.29080'

#Deployment Locations for SQL scripts
$DeploymentScriptLocations = @(
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180427\WUK.6690.30555\WUK.6690.30555',
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180522\WUK.6716.19200',
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180712\WUK.6766.20957\WUK.6766.20957',
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180720\VRUKL.6775.21600',
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180805\VRUKL.6787.27777',
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180805\VRUKL.6788.30203\VRUKL.6788.30203',
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180813\VRUKL.6794.31510',
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180813\VRUKL.6796.22920',
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180813\VRUKL.6799.22227',
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180901\VRUKL.6815.26543',
'\\vrgefs01\shared\IT\Programme Victory\Releases\Web Apps\20180901\VRUKL.6816.29080'
)
#>

#Get all the Deployment locations from the Excel Spreadsheet
$DeploymentScriptLocations = @()
$DeploymentScriptLocations = Import-Excel -Path 'C:\GitRepository\Automation\PreProd Refresh\Supporting Files\DeploymentDetails2.xlsx' -WorksheetName Deployments_9th -HeaderName WebAppsReleases  -DataOnly -Verbose

#Create local folders
$Folder = @{
    DeploymentScripts = "C:\Temp\PreProd Deployment\Scripts";
    WebAppsFileLists  = "C:\Temp\PreProd Deployment\WebAppsFileList"
}

#Create folders if not present
if (-not(Test-Path -Path $Folder.DeploymentScripts)) {New-Item -ItemType directory -Path $Folder.DeploymentScripts}
if (-not(Test-Path -Path $Folder.WebAppsFileLists)) {New-Item -ItemType directory -Path $Folder.WebAppsFileLists}

#Search each folder for SQL script, copy and rename prefixed with the order number (e.g. 1 - )
$DeploymentScripts = Get-ChildItem -Path $DeploymentScriptLocations.WebAppsReleases -Include *.sql -File -Recurse
$i = 1
$DeploymentScripts | ForEach-Object {
    $Source = $_.FullName
    $Destination = $Folder.DeploymentScripts + "\" + $i + " - " + $_.Name
    Copy-Item $Source $Destination
    $i++
}

#Filter each folder for Text file, copy and rename prefixed with the order number (e.g. 1 - )
$FileList = Get-ChildItem -Path $DeploymentScriptLocations.WebAppsReleases -Include *.txt -File -Recurse
$i = 1
$FileList | ForEach-Object {
    $Source = $_.FullName
    $Destination = $Folder.WebAppsFileLists + "\" + $i + " - " + $_.Name
    Copy-Item $Source $Destination
    $i++
}


#Search all text files for Table Changes (stb extension)
$FileListFolderTextFiles = $Folder.WebAppsFileLists + '\*.txt'
$TableChanges = Select-String -Path $FileListFolderTextFiles -Pattern stb
Clear-Host
#Display table names, file location with the line number
Write-Host 'Table Changes - '  $TableChanges.count "tables found"

$TableChanges |  Format-Table -Property Line, LineNumber, Filename, Pattern -AutoSize

#Get current Live replicated articles
$RepArticles = Invoke-DbaSqlQuery -SqlInstance 'Wercovruatsqld1,2533' -Database Master -File 'C:\GitRepository\Automation\PreProd Refresh\Supporting Files\GetReplicatedArticles.sql'

if ($TableChanges.count -gt 0) {
    $UpdatedTables = $TableChanges.Line|  ForEach-Object {
    
        $length = $_.LastIndexOf("]") - $_.LastIndexOf("[")
        $_.Substring($_.LastIndexOf("[") + 1, $length - 1)
    }
}

$ReplicatedTablesBeingUpdated = $RepArticles.ArticleName | Where-Object {$UpdatedTables -Contains $_}

if ($ReplicatedTablesBeingUpdated.count -gt 0) {
    $ReplicatedTablesBeingUpdated | ForEach-Object {Write-Host '******'  $_   'Table - currently part of Traveller Replication *****' -ForegroundColor Red} 
} 
elseif ($UpdatedTables.count -gt 0) {
    #$wshell = New-Object -ComObject Wscript.Shell
    #$wshell.Popup("The database tables being updated are NOT used by replication", 0, "Done", 0x1)
    write-host  "The database tables being updated are NOT used by replication" -ForegroundColor Yellow
}  
elseif ($UpdatedTables.count -eq 0) {
    write-host "No database tables being updated in any of the Deployments" -ForegroundColor Yellow
}

Invoke-Item $Folder.DeploymentScripts
Invoke-Item $Folder.WebAppsFileLists

