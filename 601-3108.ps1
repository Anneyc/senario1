#page2:
#installing windows ADK 
cd "C:\iso\Windows Kits\10\ADK"
Start-Process -FilePath adksetup.exe -ArgumentList "/s" -wait

#installing windows PE 
cd "C:\iso\Windows Kits\10\ADKWinPEAddons"
Start-Process -FilePath adkwinpesetup.exe -ArgumentList "/s" -wait

#installing MDT,change exe name to mdt.
cd "C:\iso"
start-process -FilePath msiexec.exe -ArgumentList "/i `"mdt.msi`" /quiet /norestart" -wait

#page5:
#create deploymentshare
cd "C:\Users\Administrator"
New-Item -path "C:\DeploymentShare" -ItemType directory
New-SmbShare -Name "DeploymentShare" -Path "C:\DeploymentShare" -FullAccess Administrators

Import-Module "C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1"

#page6:create folder windows11 at c. Server name very important.
#create a new PSDrive using the MDTProvider and then adding a persistent drive using the add-MDTPersistentDrive function.
New-PSDrive -Name "DS002" -PSProvider "MDTProvider" -Root "C:\DeploymentShare" -Description "MDT Deployment Share" -NetworkPath "\\SV\DeploymentShare" -Verbose | Add-MDTPersistentDrive -Verbose

#page9:
Import-MDTOperatingSystem -Path "DS002:\Operating Systems" -SourcePath "C:\Windows11" -DestinationFolder "windows11" -Verbose

#page11:
Import-MDTApplication -Path "DS002:\Applications" -enable "True" -Name "Adobe reader 9" -ShortName "reader" -Version "9" -Publisher "Adobe" -Language "English" -CommandLine "Reader.exe /sAll /rs /l" -WorkingDirectory ".\Applications\Adobe reader 9" -ApplicationSourcePath "C:\iso" -DestinationFolder "Adobe reader 9" -Verbose

#page13:go gui check/copy os win11 pro'name in propertie general.
Import-MDTTaskSequence -Path "DS002:\Task Sequences" -Name "Win11" -Template "Client.xml" -Comments "Deloying win11" -ID "1" -Version "1.0" -OperatingSystemPath "DS002:\Operating Systems\Windows 11 Pro in windows11 install.wim" -FullName "Windows User" -OrgName "Aspire2" -Verbose

#page14,15:copy files to desktop.
#replace the content for Bootstrap.ini,server name, domain name, same?
Remove-Item -Path "C:\DeploymentShare\Control\Bootstrap.ini" -Force 
New-Item -Path "C:\DeploymentShare\Control\Bootstrap.ini" -ItemType File 
Set-Content -Path "C:\DeploymentShare\Control\Bootstrap.ini" -Value (Get-Content "C:\Users\Administrator\Desktop\BootStrap.ini")

#replace the content for CustomSettings.ini
Remove-Item -Path "C:\DeploymentShare\Control\CustomSettings.ini" -Force 
New-Item -Path "C:\DeploymentShare\Control\CustomSettings.ini" -ItemType File 
Set-Content -Path "C:\DeploymentShare\Control\CustomSettings.ini" -Value (Get-Content "C:\Users\Administrator\Desktop\CustomSettings.ini")

#page17:
$XMLFile = "C:\DeploymentShare\Control\Settings.xml"
                                       [xml]$SettingsXML = Get-Content $XMLFile
                                       $SettingsXML.Settings. "SupportX86" = "False"
                                       $SettingsXML.Save($XMLFile)
#Update the Deployment Share to create the boot wims and iso files
Update-MDTDeploymentShare -Path "DS002:" -Force -Verbose

#page19:
#installing WDS role in the server
Install-WindowsFeature -Name WDS -IncludeManagementTools
#initialize WDS server
$WDSPath = 'C:\RemoteInstall'
wdsutil /Verbose /Progress /Initialize-Server /RemInst:$WDSPath
Start-Sleep -s 10
wdsutil /Verbose /Start-Server
Start-Sleep -s 10

#page20:
WDSUTIL /Set-Server /AnswerClients:All
#page21:
Import-WdsBootImage -Path C:\DeploymentShare\Boot\LiteTouchPE_x64.wim -NewImageName "LiteTouchPE_x64" -SkipVerify