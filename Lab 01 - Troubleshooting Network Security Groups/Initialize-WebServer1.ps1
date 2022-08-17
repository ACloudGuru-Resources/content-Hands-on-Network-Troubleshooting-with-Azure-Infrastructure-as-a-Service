#Speed up by disabling progress
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

#Install IIS
try {
    Write-Verbose "START: Installing IIS"
    Add-WindowsFeature Web-Server,Web-IP-Security -IncludeManagementTools
    Write-Verbose "END: Installing IIS"

} catch {
    Write-Verbose "ERROR: Installing IIS"
    throw $_
}
# Import WebAdministration PowerShell Module
try {
    Write-Verbose "START: Import WebAdministration"
    Import-Module WebAdministration
    Write-Verbose "END: Import WebAdministration"

}
catch {
    Write-Verbose "ERROR: Import WebAdministration"
    throw $_
}

#Install .Net Core IIS Hosting Bundle
try {
    Write-Verbose "START: Download .Net Core IIS Hosting Bundle"
    Invoke-WebRequest -Uri 'https://download.visualstudio.microsoft.com/download/pr/beca42b0-54a8-4364-86b8-a3d88003fbb7/592e0eec1e5e53f78d9647f7112cc743/dotnet-hosting-3.1.9-win.exe' -OutFile 'C:\temp\dotnet-hosting.exe'
    Write-Verbose "END: Download .Net Core IIS Hosting Bundle"
}
catch {
    Write-Verbose "ERROR: Download .Net Core IIS Hosting Bundle"
    throw $_
}

#Install the .Net Core IIS Hosting Bundle
#See: https://docs.microsoft.com/en-us/aspnet/core/tutorials/publish-to-iis?view=aspnetcore-6.0&tabs=visual-studio
try {
    Write-Verbose "START: Install .Net Core IIS Hosting Bundle"
    Start-Process -FilePath "msiexec" -ArgumentList @('/i','C:\temp\dotnet-hosting.exe','/qn','/norestart') -Wait
    Write-Verbose "END: Install .Net Core IIS Hosting Bundle"
}
catch {
    Write-Verbose "ERROR: Install .Net Core IIS Hosting Bundle"
    throw $_
}

#Secure WebServer
try {
    Write-Verbose "START: Secure WebServer"
    #Forbid other IPs from connecting to the WebServer
    Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter "system.webServer/security/ipSecurity" -name "." -value @{ipAddress='10.0.0.5';allowed='True'}
    #Disable Remote Desktop Firewall Rule
    #TODO: Add back after testing
    #Get-NetFirewallRule -Name "*RemoteDesktop*" | Where-Object Enabled -eq True | Set-NetFirewallRule -Enabled False
    Write-Verbose "END: Secure WebServer"
} catch {
    Write-Verbose "ERROR: Secure WebServer"
    throw $_
}

#Set Physical Path and Credentials
try {
    #Physical Path
    Write-Verbose "START: Set Physical Path and Credentials"
    Set-ItemProperty 'IIS:\Sites\Default Web Site\' -Name physicalPath -Value '\\10.0.1.139\Web'
    Set-ItemProperty 'IIS:\Sites\Default Web Site\' -Name userName -Value 'DoNotUse'
    Set-ItemProperty 'IIS:\Sites\Default Web Site\' -Name password -Value 'DoNotUse!'
    #App Pool
    Set-ItemProperty IIS:\AppPools\DefaultAppPool -name processModel.identityType -Value SpecificUser
    Set-ItemProperty IIS:\AppPools\DefaultAppPool -name processModel.userName -Value "DoNotUse"
    Set-ItemProperty IIS:\AppPools\DefaultAppPool -name processModel.password -Value "DoNotUse!"
    Write-Verbose "END: Set Physical Path and Credentials"
}
catch {
    Write-Verbose "ERROR: Set Physical Path and Credentials"
    throw $_
}
#Restart the required services
try {
    Write-Verbose "START: Restart required services"
    Restart-Service -Name was -Force
    Start-Service -Name w3svc
    Write-Verbose "END: Restart required services"
}
catch {
    Write-Verbose "ERROR: Restart required services"
    throw $_
}