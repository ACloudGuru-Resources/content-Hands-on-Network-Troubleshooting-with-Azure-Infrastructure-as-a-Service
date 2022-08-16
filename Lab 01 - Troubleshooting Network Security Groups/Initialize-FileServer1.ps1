$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Install-WindowsFeature FS-FileServer
New-Item -Path C:\ -Name Web -ItemType Directory
New-SmbShare -Path C:\Web -Name Web
New-Item -Path C:\Web -Name "index.html"
Set-Content -Path C:\Web\index.html -Value "<html><h1>Website from FS01</h1></html>"