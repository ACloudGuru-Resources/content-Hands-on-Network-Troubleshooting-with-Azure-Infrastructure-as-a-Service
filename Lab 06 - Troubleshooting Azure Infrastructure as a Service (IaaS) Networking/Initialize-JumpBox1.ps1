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

#Set Scheduled Tasks
# Deploy Virus
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Shared/index.html' -OutFile 'C:\Temp\index.html'
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Install-Virus.ps1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once
Register-ScheduledTask -TaskName "Install-Virus" -Action $Action -Trigger $Trigger -Description "Install Virus" -RunLevel Highest -User "System"

#Generate a random number
$Random = Get-Random -Minimum 1 -Maximum 10
if ($Random -le 5) {
    #Add a hosts entry to break DNS
    Add-Content -Value "192.168.0.1 escape.lab.vnet" -Path "C:\Windows\System32\drivers\etc\hosts"
} else {
    #Add a Firewall Rule to break outbound port 80
    New-NetFirewallRule -DisplayName "Block Outbound Port 80" -Direction Outbound -LocalPort 80 -Protocol TCP -Action Block -Profile Any
    Enable-NetFirewallRule -DisplayName "Block Outbound Port 80"
}