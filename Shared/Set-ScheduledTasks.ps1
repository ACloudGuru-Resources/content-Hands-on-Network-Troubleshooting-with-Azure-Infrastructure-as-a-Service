# Remove-Deployments
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Temp\Remove-Deployments.ps1"
$Trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(3) -RepetitionInterval (New-TimeSpan -Minutes 1) -Once 
Register-ScheduledTask -TaskName "Remove-Deployments" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Deployments"
Start-ScheduledTask -TaskName "Remove-Deployments"