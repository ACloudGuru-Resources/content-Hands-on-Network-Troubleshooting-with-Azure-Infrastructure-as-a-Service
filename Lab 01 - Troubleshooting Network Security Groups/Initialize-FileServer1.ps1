$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Install-WindowsFeature FS-FileServer
New-Item -Path C:\ -Name Web -ItemType Directory
New-SmbShare -Path C:\Web -Name Web
Invoke-WebRequest -Uri '' -OutFile 'C:\temp\WebApp.zip'
Expand-Archive -Path 'C:\temp\WebApp.zip' -DestinationPath 'C:\Web' -Force