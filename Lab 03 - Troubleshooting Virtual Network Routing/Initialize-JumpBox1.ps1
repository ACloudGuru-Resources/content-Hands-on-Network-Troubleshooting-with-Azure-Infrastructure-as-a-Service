$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "Edge"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name 'HideFirstRunExperience' -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HomepageLocation" -Value "http://10.0.1.80"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "RestoreOnStartupURLs" -Value "http://10.0.1.80"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "RestoreOnStartup" -Value 4

#Install Modules
Install-PackageProvider -Name 'Nuget' -MinimumVersion 2.8.5.201 -Force
Install-Module 'Az.Accounts','Az.Compute','Az.Resources' -Force

#Download Scripts
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Shared/Remove-Deployments.ps1' -OutFile 'C:\temp\Remove-Deployments.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Shared/Remove-CustomScriptExtension.ps1' -OutFile 'C:\temp\Remove-CustomScriptExtension.ps1'

#Set Scheduled Tasks
# Deploy Virus
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Shared/index.html' -OutFile 'C:\Temp\index.html'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Shared/Install-Virus.ps1' -OutFile 'C:\Temp\Install-Virus.ps1'
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Install-Virus.ps1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once
Register-ScheduledTask -TaskName "Install-Virus" -Action $Action -Trigger $Trigger -Description "Install Virus" -RunLevel Highest -User "System"

# Remove Deployments
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-Deployments.ps1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once
Register-ScheduledTask -TaskName "Remove-Deployments" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Deployments" -RunLevel Highest -User "System"

#Remove Custom Script Extensions
# WebServer1
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName WebServer1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once 
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension WebServer1" -Action $Action -Trigger $Trigger -Description "Clean-up Extensions" -RunLevel Highest -User "System"

# FileServer1
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName FileServer1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension FileServer1" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Extensions" -RunLevel Highest -User "System"

# Jumpbox1
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName Jumpbox1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension Jumpbox1" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Extensions" -RunLevel Highest -User "System"

# Jumpbox2
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Remove-CustomScriptExtension.ps1 -VMName Jumpbox2"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once
Register-ScheduledTask -TaskName "Remove-CustomScriptExtension Jumpbox2" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Extensions" -RunLevel Highest -User "System"