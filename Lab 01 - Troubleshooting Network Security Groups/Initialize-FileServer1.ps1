$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Install-WindowsFeature FS-FileServer
New-Item -Path C:\ -Name Web -ItemType Directory
New-SmbShare -Path C:\Web -Name Web
Invoke-WebRequest -Uri 'https://github.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/raw/master/Lab%2001%20-%20Troubleshooting%20Network%20Security%20Groups/WebApp/WebApp.zip' -OutFile 'C:\temp\WebApp.zip'
Expand-Archive -Path 'C:\temp\WebApp.zip' -DestinationPath 'C:\Web' -Force