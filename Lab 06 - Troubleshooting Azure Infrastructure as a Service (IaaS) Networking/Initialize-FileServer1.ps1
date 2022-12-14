$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Install-WindowsFeature FS-FileServer
New-Item -Path C:\ -Name Web -ItemType Directory
New-SmbShare -Path C:\Web -Name Web -FullAccess Everyone
Invoke-WebRequest -Uri 'https://github.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/raw/master/Lab%2006%20-%20Troubleshooting%20Azure%20Infrastructure%20as%20a%20Service%20(IaaS)%20Networking/WebApp/WebApp.zip' -OutFile 'C:\temp\WebApp.zip'
Expand-Archive -Path 'C:\temp\WebApp.zip' -DestinationPath 'C:\Web' -Force

#Install Modules
Install-PackageProvider -Name 'Nuget' -MinimumVersion 2.8.5.201 -Force
Install-Module 'Az.Accounts','Az.Compute','Az.Resources' -Force

#Download Scripts
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Shared/Remove-Deployments.ps1' -OutFile 'C:\temp\Remove-Deployments.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Shared/Remove-CustomScriptExtension.ps1' -OutFile 'C:\temp\Remove-CustomScriptExtension.ps1'

#Set Scheduled Tasks
# Remove Deployments
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-Deployments.ps1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once
Register-ScheduledTask -TaskName "Remove-Deployments" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Deployments" -RunLevel Highest -User "System"

#Remove Custom Script Extensions
# WebServer1
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName WebServer1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(8) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once 
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension WebServer1" -Action $Action -Trigger $Trigger -Description "Clean-up Extensions" -RunLevel Highest -User "System"

# FileServer1
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName FileServer1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(8) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension FileServer1" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Extensions" -RunLevel Highest -User "System"

# Jumpbox1
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName Jumpbox1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(8) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension Jumpbox1" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Extensions" -RunLevel Highest -User "System"

# Jumpbox2
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName Jumpbox2"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(8) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension Jumpbox2" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Extensions" -RunLevel Highest -User "System"