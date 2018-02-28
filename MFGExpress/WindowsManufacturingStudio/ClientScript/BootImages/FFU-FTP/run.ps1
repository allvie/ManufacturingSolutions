﻿$RootDir = Split-Path -parent $MyInvocation.MyCommand.Definition;

if($RootDir.EndsWith("\") -eq $true)
{
   $RootDir = $RootDir.Substring(0, ($RootDir.Length -1));
}

$ErrorActionPreference = "Stop";

[System.DateTime]$StartTime = [System.DateTime]::Now;

[xml]$ConfigXml = Get-Content -Path ($RootDir + "\config.xml") -Encoding UTF8;

$ConfigXml.InnerXml;

$ImageServerAddress = $ConfigXml.configurationItems.imageServerAddress; #"minint-et2evvt";
$ImageServerUserName= $ConfigXml.configurationItems.imageServerUserName; #"Administrator";
$ImageServerPassword = $ConfigXml.configurationItems.imageServerPassword; #"W@lcome!";
$NICName = $ConfigXml.configurationItems.nicName;
[int]$ClientIdentifierType = $ConfigXml.configurationItems.clientIdentifierType;
[int]$ImageIdentifierType = $ConfigXml.configurationItems.imageIdentifierType;

$ImageDestination = $ConfigXml.configurationItems.imageDestination;

[System.String]$WDSApiServicePoint = $ConfigXml.configurationItems.wdsApiServicePoint; #"http://minint-et2evvt:8089";

if($WDSApiServicePoint.EndsWith("/") -eq $false)
{
   $WDSApiServicePoint += "/";
}

$ImageServerAddress;
$ImageServerUserName;
$WDSApiServicePoint;

Import-Module -Name ($RootDir + "\PSModuleFTPClient\PowerShellFTPClient.dll");

$TransactionID = [System.Guid]::NewGuid().ToString();

$ClientID = "";
$ImageID = "";

if($ClientIdentifierType -eq 0)
{
	$ComputerBIOS = Get-CimInstance CIM_BIOSElement;
	$SerialNumber = $ComputerBIOS.SerialNumber;
	$ClientID = $SerialNumber;
}

if($ClientIdentifierType -eq 1)
{
	$MacObject = Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.MacAddress -and $_.Name -eq $NICName} | Select-Object Name, MacAddress; 
	$MacAddress = $MacObject.MacAddress;
	$ClientID = $MacAddress;
}

if([System.String]::IsNullOrEmpty($ClientID))
{
	$ClientID = $ConfigXml.configurationItems.clientIdentifierValue;
}

$ClientID;

$Body = ConvertFrom-Json -InputObject "{`"Key`":`"`", `"Value`":`"`", `"Data`":`"`", `"TransID`":`"`", `"Time`":`"`"}";
$Body.TransID = $TransactionID;
$Body.Key = $ClientID;

[System.String]$Url = "wds/lookup/";
[System.String]$UrlProgress = "wds/terminal/status/";
[System.String]$UrlImageFileInfo = "wds/imagefile/info/ffu/";
[System.String]$UrlLogFile = ("wds/logfile/{0}" -f $TransactionID);

$Body.Value = "GettingSKUFromBIOS";
$Body.Time = [System.DateTime]::Now;
$BodyJson = ConvertTo-Json -InputObject $Body;
Invoke-RestMethod -Method Post -Uri ($WDSApiServicePoint + $UrlProgress) -Body $BodyJson -ContentType "application/json";

if($ImageIdentifierType -eq 0)
{
	$SystemInfo = Get-CimInstance -ClassName Win32_ComputerSystem;
	$SKU = $SystemInfo.SystemSKUNumber;
	$ImageID = $SKU;
}

if($ImageIdentifierType -eq 1)
{
   $SystemInfo = Get-CimInstance -ClassName Win32_ComputerSystem;
   $Model = $SystemInfo.Model;
   $ImageID = $Model;
}

if($ImageIdentifierType -eq 2)
{
   $SystemInfo = Get-CimInstance -ClassName Win32_ComputerSystem;
   $ImageID = $SystemInfo.SystemFamily;
}

if($ImageIdentifierType -eq 3)
{
   $SystemInfo = Get-CimInstance -ClassName Win32_ComputerSystem;
   $ImageID = $SystemInfo.Manufacturer;
}

if([System.String]::IsNullOrEmpty($ImageID))
{
	$ImageID = $ConfigXml.configurationItems.imageIdentifierValue;
}

$ImageID;

if([System.String]::IsNullOrEmpty($ImageID))
{
    $Host.UI.RawUI.BackgroundColor = "Red";
    $Host.UI.RawUI.ForegroundColor = "Yellow";
    Write-Host -Object "The specified image identifier field in SMBIOS is empty!";
	Read-Host -Prompt "The specified image identifier field in SMBIOS is empty! `nPress any key to exit...";
    exit;
}

$Body.Value = "GettingImageConfiguration";
$Body.Time = [System.DateTime]::Now;
$BodyJson = ConvertTo-Json -InputObject $Body;
Invoke-RestMethod -Method Post -Uri ($WDSApiServicePoint + $UrlProgress) -Body $BodyJson -ContentType "application/json";

$Uri = $WDSApiServicePoint + $Url + $ImageID;
$Uri;
$ImageConfig = Invoke-RestMethod -Method Get -Uri $Uri;
$ImageConfig;

#$ImageConfig = ConvertFrom-Json -InputObject $ImageConfigJson;


if([System.String]::IsNullOrEmpty($ImageConfig.ImageServerAddress) -eq $false)
{
	 $ImageServerAddress = $ImageConfig.ImageServerAddress;
}

if([System.String]::IsNullOrEmpty($ImageConfig.ImageServerUsername) -eq $false)
{
	 $ImageServerUserName = $ImageConfig.ImageServerUsername;
}

if([System.String]::IsNullOrEmpty($ImageConfig.ImageServerPassword) -eq $false)
{
	 $ImageServerPassword = $ImageConfig.ImageServerPassword;
}

if([System.String]::IsNullOrEmpty($ImageConfig.ImageDestination) -eq $false)
{
	 $ImageDestination = $ImageConfig.ImageDestination;
}

if($ImageServerAddress.EndsWith("/") -eq $false)
{
   $ImageServerAddress += "/";
}

$ImageUrl = $ImageConfig.ImageSource;

$Body.Value = "GettingImageFileInfo";
$Body.Time = [System.DateTime]::Now;
$BodyJson = ConvertTo-Json -InputObject $Body;
Invoke-RestMethod -Method Post -Uri ($WDSApiServicePoint + $UrlProgress) -Body $BodyJson -ContentType "application/json";

$RemoteImageFileName = $ImageUrl.Substring(($ImageUrl.LastIndexOf("/") + 1));
$Uri= $WDSApiServicePoint + $UrlImageFileInfo + $RemoteImageFileName;
$Uri;

$RemoteImageFileInfo = Invoke-RestMethod -Method Get -Uri $Uri;

$ImageFilePath = ("D:\{0}.ffu" -f $ImageID);
$ImageFilePath;
$ImageFileInfoPath = ("D:\{0}.ffu.info.json" -f $ImageID);
$ImageFileInfoPath;

if(([System.IO.File]::Exists($ImageFilePath) -eq $true) -and ([System.IO.File]::Exists($ImageFileInfoPath) -eq $true))
{
   $LocalImageFileInfoJson = Get-Content -Path $ImageFileInfoPath;
   $LocalImageFileInfo = ConvertFrom-Json -InputObject $LocalImageFileInfoJson;

   $ImageFile = Get-Item -Path $ImageFilePath;

   if(($ImageFile.Length -ne $RemoteImageFileInfo.size) -or ($LocalImageFileInfo.atime -ne $RemoteImageFileInfo.atime) -or ($LocalImageFileInfo.birthtime -ne $RemoteImageFileInfo.birthtime) -or ($LocalImageFileInfo.ctime -ne $RemoteImageFileInfo.ctime) -or ($LocalImageFileInfo.mtime -ne $RemoteImageFileInfo.mtime) -or ($LocalImageFileInfo.size -ne $RemoteImageFileInfo.size) -or ($LocalImageFileInfo.ino -ne $RemoteImageFileInfo.ino))
   {
       [System.IO.File]::Delete($ImageFileInfoPath);
	   [System.IO.File]::Delete($ImageFilePath);
   }
}

if([System.IO.File]::Exists($ImageFilePath) -eq $false)
{
    #Clear local FFU image cache
    [System.String[]]$files = [System.IO.Directory]::GetFiles("D:\", "*.ffu*", [System.IO.SearchOption]::AllDirectories);
	if(($files -ne $null) -and ($files.Length -gt 0))
	{
		foreach($file in $files)
		{
			[System.IO.File]::Delete($file);
		}    
	}
    
    #$Body.Value = "GettingImageUrl";
	#$Body.Time = [System.DateTime]::Now;
	#$BodyJson = ConvertTo-Json -InputObject $Body;
	#Invoke-RestMethod -Method Post -Uri ($WDSApiServicePoint + $UrlProgress) -Body $BodyJson -ContentType "application/json";

	#$Uri = $WDSApiServicePoint + $Url + $ImageID;

	#$Uri;

	#[System.String]$ImageUrl = Invoke-RestMethod -Method Get -Uri $Uri;

	#$ImageUrl;

	$Body.Value = "DownloadingImage";
	$Body.Time = [System.DateTime]::Now;
	$BodyJson = ConvertTo-Json -InputObject $Body;
	Invoke-RestMethod -Method Post -Uri ($WDSApiServicePoint + $UrlProgress) -Body $BodyJson -ContentType "application/json";


	if($ImageUrl.StartsWith("/"))
	{
	   $ImageUrl = $ImageUrl.Substring(($ImageUrl.IndexOf("/") + 1));
	}

	$ImageUrl = $ImageServerAddress + $ImageUrl;

	$ImageUrl;

	#$auth = [System.String]::Format("{0}:{1}", $ImageServerUserName, $ImageServerPassword);

	#$authBytes = [System.Text.Encoding]::UTF8.GetBytes($auth);

	#$authBase64 = [System.Convert]::ToBase64String($authBytes);

	#$AuthHeaderValue = [System.String]::Format("Basic {0}",$authBase64);

	#$ImageFilePath = $ImageUrl.Substring(($ImageUrl.LastIndexOf("/") + 1));

	#$ImageFilePath = [System.String]::Format("D:\{0}_{1}", [System.Guid]::NewGuid().ToString() , $ImageFilePath);

	#$AuthHeaderValue;

	#$ImageFilePath;

	#[System.Net.WebClient]$WebClient = [System.Net.WebClient]::new();

	#$WebClient.Credentials = New-Object System.Net.NetworkCredential($ImageServerUserName,$ImageServerPassword);

	##$WebClient.Headers.Add([System.Net.HttpRequestHeader]::Authorization, $AuthHeaderValue);

	##$WebClient.DownloadFile($ImageUrl, $ImageFilePath);

	#Register-ObjectEvent -InputObject $WebClient -EventName DownloadFileCompleted -SourceIdentifier Web.DownloadFileCompleted -Action { $Global:isDownloaded = $True; };

	#Register-ObjectEvent -InputObject $WebClient -EventName DownloadProgressChanged -SourceIdentifier Web.DownloadProgressChanged -Action { $Global:Data = $event; };

	#$WebClient.DownloadFileAsync($ImageUrl ,$ImageFilePath);

	#While (-Not $isDownloaded) 
	#{
	#	$percent = $Global:Data.SourceArgs.ProgressPercentage;
	#	$totalBytes = $Global:Data.SourceArgs.TotalBytesToReceive;
	#	$receivedBytes = $Global:Data.SourceArgs.BytesReceived;

	#	If ($percent -ne $null) 
	#	{
	#		Write-Progress -Activity ("Downloading {0} from {1}" -f $ImageFilePath, $ImageUrl) -Status ("{0} bytes \ {1} bytes" -f $receivedBytes,$totalBytes) -PercentComplete $percent;
	#	}
	#}

	#Write-Progress -Activity ("Downloading {0} from {1}" -f $ImageFilePath, $ImageUrl) -Status ("{0} bytes \ {1} bytes" -f $receivedBytes,$totalBytes) -Completed;

	[System.Uri]$ImageFileUri = New-Object -TypeName "System.Uri" -ArgumentList($ImageUrl);

	Get-FTPFile -Host $ImageFileUri.Host -Port $ImageFileUri.Port -UserName $ImageServerUserName -Password $ImageServerPassword -RemoteName $ImageFileUri.PathAndQuery -LocalName $ImageFilePath;
}


#Start-Process -FilePath "HttpFileClient.exe" -ArgumentList @($ImageUrl, $ImageFilePath, "Basic", $authBase64) -Wait;


#%WINDIR%\System32\Wdsmcast\wdsmcast.exe /progress /verbose /trace:wds_trace.etl /Transfer-File /Server:192.168.0.215 /Namespace:WDS:Group-Windows8/Win8-Windows.wim/1 /Username:WIN-Server-02\Administrator /Password:P@ssword! /SourceFile:Win8-Windows.wim /DestinationFile:R:\install.wim
#& (wdsmcast.exe) @("/progress", "/verbose", "/trace:wds_trace.etl", "/Transfer-File", ("/Server:" + $ImageServerAddress), ("/Namespace:" + $WDSImageNameSpace),  ("/Username:" + $ImageServerAddress + "\" + $ImageServerUserName), ("/Password:" + $ImageServerPassword),  ("/SourceFile:" + $WDSImageSource), "/DestinationFile:R:\install.wim");
#Start-Process -FilePath "wdsmcast.exe" -ArgumentList @("/progress", "/verbose", "/trace:wds_trace.etl", "/Transfer-File", ("/Server:" + $ImageServerAddress), ("/Namespace:" + $WDSImageNameSpace), ("/Username:" + $ImageServerAddress + "\" + $ImageServerUserName), ("/Password:" + $ImageServerPassword), ("/SourceFile:" + $WDSImageSource), "/DestinationFile:R:\install.wim") -Wait -NoNewWindow;

#%WINDIR%\System32\Wdsmcast\wdsmcast.exe /progress /verbose /trace:wds_trace.etl /Apply-Image /Server:192.168.0.215 /Namespace:WDS:Group-Windows8/Win8-Windows.wim/1 /Username:WIN-Server-02\Administrator /Password:P@ssword! /SourceFile:Win8-Windows.wim /Index:1 /DestinationPath:W:\
#Start-Process -FilePath "wdsmcast.exe" -ArgumentList @("/progress", "/verbose", "/trace:wds_trace.etl", "/Apply-Image", ("/Server:" + $ImageServerAddress), ("/Namespace:" + $WDSImageNameSpace), ("/Username:" + $ImageServerAddress + "\" + $ImageServerUserName), ("/Password:" + $ImageServerPassword), ("/SourceFile:" + $WDSImageSource), "/Index:1", "/DestinationPath:W:\") -Wait -NoNewWindow;

#DISM /Apply-Image /ImageFile:R:\install.wim /ApplyDir:W:\ /Index:1  /ScratchDir:R:\TEMP

#mkdir R:\TEMP;

#Expand-WindowsImage -ImagePath "R:\install.wim" -ApplyPath "W:\" -Index 1 -ScratchDirectory "R:\TEMP";

$Body.Value = "CheckingImageFileIntegrity";
$Body.Time = [System.DateTime]::Now;
$BodyJson = ConvertTo-Json -InputObject $Body;
Invoke-RestMethod -Method Post -Uri ($WDSApiServicePoint + $UrlProgress) -Body $BodyJson -ContentType "application/json";

$ImageFile = Get-Item -Path $ImageFilePath;

if($ImageFile.Length -eq $RemoteImageFileInfo.size)
{
    $RemoteImageFileInfoJson = ConvertTo-Json -InputObject $RemoteImageFileInfo -Compress;
    [System.IO.File]::WriteAllText($ImageFileInfoPath, $RemoteImageFileInfoJson);
}
else
{
    [System.IO.File]::Delete($ImageFilePath);

	$Host.UI.RawUI.BackgroundColor = "Red";
    $Host.UI.RawUI.ForegroundColor = "Yellow";
    Write-Host -Object ("Image file size incorrect, please try downloading it again! (Expected Size: {0}; Actual Size: {1})" -f  $RemoteImageFileInfo.size, $ImageFile.Length);
	Read-Host -Prompt ("Image file size incorrect, please try downloading it again! (Expected Size: {0}; Actual Size: {1}) `nPress any key to exit..."-f  $RemoteImageFileInfo.size, $ImageFile.Length);
    exit;
}

$Body.Data = $ImageUrl;
$Body.Value = "ApplyingImage";
$Body.Time = [System.DateTime]::Now;
$BodyJson = ConvertTo-Json -InputObject $Body;
Invoke-RestMethod -Method Post -Uri ($WDSApiServicePoint + $UrlProgress) -Body $BodyJson -ContentType "application/json";

#Start-Process -FilePath ".\DISM-FFU\DISM.exe" -ArgumentList @("/Apply-FFU", ("/ImageFile:" + $ImageFilePath), "/ApplyDrive:\\.\PhysicalDrive0") -Wait -NoNewWindow;
#Start-Process -FilePath "DISM" -ArgumentList @("/Apply-FFU", ("/ImageFile:" + $ImageFilePath), "/ApplyDrive:\\.\PhysicalDrive0") -Wait -NoNewWindow;

if([System.String]::IsNullOrEmpty($ImageDestination) -eq $true)
{
   $ImageDestination = "\\.\PhysicalDrive0";
}

Start-Process -FilePath "DISM" -ArgumentList @("/Apply-FFU", ("/ImageFile:" + $ImageFilePath), ("/ApplyDrive:" + $ImageDestination)) -Wait -NoNewWindow;

$Body.Value = "ImageApplied";
$Body.Time = [System.DateTime]::Now;
$BodyJson = ConvertTo-Json -InputObject $Body;
Invoke-RestMethod -Method Post -Uri ($WDSApiServicePoint + $UrlProgress) -Body $BodyJson -ContentType "application/json";

#Copy-Item -Path X:\Windows\Logs\DISM\dism.log -Destination ("D:\dismlog_{0}_{1}.log" -f $ImageID, $TransactionID) -Force;

$WebClient = [System.Net.WebClient]::new();
$WebClient.UploadFileAsync(($WDSApiServicePoint + $UrlLogfile), "X:\Windows\Logs\DISM\dism.log");

[System.DateTime]$EndTime = [System.DateTime]::Now;
[System.TimeSpan]$TimeSpan = $EndTime.Subtract($StartTime);
$Message = ("Total time spent: {0} seconds ({1} minutes)." -f $TimeSpan.TotalSeconds, $TimeSpan.TotalMinutes);
$Host.UI.RawUI.BackgroundColor = "Yellow";
$Host.UI.RawUI.ForegroundColor = "Green";
Write-Host -Object $Message;

#Function Clear-LocalFFUCache
#{
#   [System.String[]]$files = [System.IO.Directory]::GetFiles("D:\", "*.ffu", [System.IO.SearchOption]::AllDirectories);

#   if($files -ne $null -and $files.Length -gt 0)
#   {
#       foreach($file in $files)
#	   {
#	      [System.IO.File]::Delete($file);
#	   }    
#   }
#}