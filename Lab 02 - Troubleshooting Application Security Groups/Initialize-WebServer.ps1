#Speed up by disabling progress
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
 
#Install IIS
try {
    Write-Verbose "START: Installing IIS"
    Add-WindowsFeature Web-Server, Web-IP-Security -IncludeManagementTools
    Write-Verbose "END: Installing IIS"
 
}
catch {
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

#Download .Net Core IIS Hosting Bundle
try {
    Write-Verbose "START: Download .Net Core IIS Hosting Bundle"
    Invoke-WebRequest -Uri 'https://github.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/raw/master/Shared/Software/dotnet-hosting.exe' -OutFile 'C:\temp\dotnet-hosting.exe'
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
    Start-Process -FilePath "C:\temp\dotnet-hosting.exe" -ArgumentList @('/quiet', '/norestart') -Wait -PassThru
    Write-Verbose "END: Install .Net Core IIS Hosting Bundle"
}
catch {
    Write-Verbose "ERROR: Install .Net Core IIS Hosting Bundle"
    throw $_
}

#Download the Core Module
#Note: This should be installed automatically, but it wasn't, so manual it is!
try {
    Write-Verbose "START: Download .Net Core Module"
    Invoke-WebRequest -Uri 'https://github.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/raw/master/Shared/Software/AspNetCoreModuleV2_x64.msi' -OutFile 'C:\temp\AspNetCoreModuleV2_x64.msi'
    Write-Verbose "END: Download .Net Core Module"
}
catch {
    Write-Verbose "ERROR: Download .Net Core Module"
    throw $_
}

#Install Core Module
try {
    Write-Verbose "START: Install .Net Core Module"
    Start-Process -FilePath 'msiexec' -ArgumentList @('/i "C:\Temp\AspNetCoreModuleV2_x64.msi"', '/qn') -Wait 
    Write-Verbose "END: Install .Net Core Module"
}
catch {
    Write-Verbose "ERROR: Install .Net Core Module"
    throw $_
}

#Secure WebServer
try {
    Write-Verbose "START: Secure WebServer"
    #Forbid other IPs from connecting to the WebServer
    Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter "system.webServer/security/ipSecurity" -name "." -value @{ipAddress = '10.0.2.0'; subnetMask='255.255.255.0'; allowed = 'True' }
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter "system.webServer/security/ipSecurity" -name "allowUnlisted" -value "False"
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter "system.webServer/security/ipSecurity" -name "denyAction" -value "Forbidden"
    #Disable Remote Desktop Firewall Rule
    #TODO: Add back after testing
    #Get-NetFirewallRule -Name "*RemoteDesktop*" | Where-Object Enabled -eq True | Set-NetFirewallRule -Enabled False
    Write-Verbose "END: Secure WebServer"
}
catch {
    Write-Verbose "ERROR: Secure WebServer"
    throw $_
}

#Copy Webserver Content
Invoke-WebRequest -Uri 'TODO:' -OutFile 'C:\temp\WebApp.zip'
Expand-Archive -Path 'C:\temp\WebApp.zip' -DestinationPath 'C:\inetpub\wwwroot' -Force

#Restart IIS Services
try {
    Write-Verbose "START: Restart required services"
    Stop-Service -Name was -Force
    Start-Service -Name w3svc
    Write-Verbose "END: Restart required services"
}
catch {
    Write-Verbose "ERROR: Restart required services"
    throw $_
} 
