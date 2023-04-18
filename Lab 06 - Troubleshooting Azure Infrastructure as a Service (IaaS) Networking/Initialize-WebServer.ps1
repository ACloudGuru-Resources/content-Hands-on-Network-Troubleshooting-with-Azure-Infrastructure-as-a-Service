$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

Start-Job -Name "IIS" -ScriptBlock {
    #Install IIS
    Add-WindowsFeature Web-Server, Web-IP-Security -IncludeManagementTools
    # Import WebAdministration PowerShell Module
    Import-Module WebAdministration
    #Download .Net Core IIS Hosting Bundle
    try {
        Write-Verbose "START: Download .Net Core IIS Hosting Bundle"
        Invoke-WebRequest -Uri 'https://download.visualstudio.microsoft.com/download/pr/6744eb9d-dcd4-4386-9d87-b03b70fc58ce/818fadf3f3d919c17ba845b2195bfd9b/dotnet-hosting-3.1.32-win.exe' -OutFile 'C:\temp\dotnet-hosting.exe'
        Write-Verbose "END: Download .Net Core IIS Hosting Bundle"
    }
    catch {
        Write-Verbose "ERROR: Download .Net Core IIS Hosting Bundle"
        throw $_
    }

    #Install the .Net Core IIS Hosting Bundle
    try {
        Write-Verbose "START: Install .Net Core IIS Hosting Bundle"
        Start-Process -FilePath "C:\temp\dotnet-hosting.exe" -ArgumentList @('/quiet', '/norestart') -Wait -PassThru
        Write-Verbose "END: Install .Net Core IIS Hosting Bundle"
    }
    catch {
        Write-Verbose "ERROR: Install .Net Core IIS Hosting Bundle"
        throw $_
    }
    #Secure WebServer
    Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter "system.webServer/security/ipSecurity" -name "." -value @{ipAddress = '10.1.0.5'; allowed = 'True' }
    Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter "system.webServer/security/ipSecurity" -name "." -value @{ipAddress = '10.1.0.6'; allowed = 'True' }
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter "system.webServer/security/ipSecurity" -name "allowUnlisted" -value "False"
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter "system.webServer/security/ipSecurity" -name "denyAction" -value "Forbidden"
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site'  -filter "system.webServer/aspNetCore" -name "stdoutLogEnabled" -value "True"
    #Set DNS Host Header for website
    Set-WebBinding -Name 'Default Web Site' -BindingInformation '*:80:' -PropertyName HostHeader -Value 'escape.lab.vnet'
    #Set Physical Path and Credentials
    #Physical Path
    Set-ItemProperty 'IIS:\Sites\Default Web Site\' -Name physicalPath -Value '\\10.0.1.139\Web'
    Set-ItemProperty 'IIS:\Sites\Default Web Site\' -Name userName -Value 'DoNotUse'
    Set-ItemProperty 'IIS:\Sites\Default Web Site\' -Name password -Value 'SuperSecureP@55w0rd'
    #App Pool
    Set-ItemProperty IIS:\AppPools\DefaultAppPool -name processModel.identityType -Value SpecificUser
    Set-ItemProperty IIS:\AppPools\DefaultAppPool -name processModel.userName -Value "DoNotUse"
    Set-ItemProperty IIS:\AppPools\DefaultAppPool -name processModel.password -Value "SuperSecureP@55w0rd"
    }

Start-Job -Name "Firewall" -ScriptBlock {
    #Disable Remote Desktop Firewall Rule
    Get-NetFirewallRule -Name "*RemoteDesktop*" | Where-Object Enabled -eq True | Set-NetFirewallRule -Enabled False
}

Start-Job -Name "EnvironmentVariables" -ScriptBlock {
    Install-PackageProvider -Name 'Nuget' -MinimumVersion 2.8.5.201 -Force
    Install-Module 'Az.Accounts','Az.Storage' -Force
    Connect-AzAccount -Identity
    [Environment]::SetEnvironmentVariable('STORAGE_ACCOUNT', "$((Get-AzStorageAccount).StorageAccountName)", 'Machine')
}

while (Get-Job -State Running) {
    Start-Sleep -Seconds 1
}
#Restart IIS last to load Envinronment variables
Stop-Service -Name was -Force
Start-Service -Name w3svc