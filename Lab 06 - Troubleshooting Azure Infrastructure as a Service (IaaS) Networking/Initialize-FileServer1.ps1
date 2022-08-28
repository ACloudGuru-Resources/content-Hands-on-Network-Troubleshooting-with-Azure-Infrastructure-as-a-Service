$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Install-WindowsFeature FS-FileServer
New-Item -Path C:\ -Name Web -ItemType Directory
New-SmbShare -Path C:\Web -Name Web
Invoke-WebRequest -Uri 'https://github.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/raw/master/Lab%2001%20-%20Troubleshooting%20Network%20Security%20Groups/WebApp/WebApp.zip' -OutFile 'C:\temp\WebApp.zip'
Expand-Archive -Path 'C:\temp\WebApp.zip' -DestinationPath 'C:\Web' -Force

#Download Scripts
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Shared/Remove-Deployments.ps1' -OutFile 'C:\temp\Remove-Deployments.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Shared/Remove-CustomScriptExtension.ps1' -OutFile 'C:\temp\Remove-CustomScriptExtension.ps1'

#Set Scheduled Tasks
# Remove Deployments
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-Deployments.ps1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(3) -RepetitionInterval (New-TimeSpan -Minutes 1) 
Register-ScheduledTask -TaskName "Remove-Deployments" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Deployments"
Start-ScheduledTask -TaskName "Remove-Deployments"

#Remove Custom Script Extensions
# WebServer1
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName WebServer1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(3) -RepetitionInterval (New-TimeSpan -Minutes 1) 
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension WebServer1" -Action $Action -Trigger $Trigger -Description "Clean-up Extensions"
Start-ScheduledTask -TaskName "Remove-CustomScriptExtension WebServer1"

# WebServer1
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName FileServer1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(3) -RepetitionInterval (New-TimeSpan -Minutes 1) 
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension FileServer1" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Extensions"
Start-ScheduledTask -TaskName "Remove-CustomScriptExtension FileServer1"

# Jumpbox1
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName Jumpbox1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(3) -RepetitionInterval (New-TimeSpan -Minutes 1) 
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension Jumpbox1" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Extensions"
Start-ScheduledTask -TaskName "Remove-CustomScriptExtension Jumpbox1"

# Jumpbox2
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName Jumpbox2"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(3) -RepetitionInterval (New-TimeSpan -Minutes 1) 
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension Jumpbox2" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Extensions"
Start-ScheduledTask -TaskName "Remove-CustomScriptExtension Jumpbox2"