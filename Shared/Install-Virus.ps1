$ErrorActionPreference = "SilentlyContinue"
if (-not (Get-Item C:\Temp\index.html)) {
    Invoke-WebRequest -Uri '' -OutFile 'C:\Temp\index.html'
}
Import-Module bitstransfer
$Username = '.\DoNotUse'
$Password = ConvertTo-SecureString "SuperSecureP@55w0rd" -AsPlainText -Force
[pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
$Destinations = @('\\10.0.1.139\Web','\\10.0.1.80\c$\inetpub\wwwroot','\\10.0.0.80\c$\inetpub\wwwroot')
foreach ($Destination in $Destinations) {
    New-PSDrive -Name X -PSProvider FileSystem -Root "$($Destination)"  -Credential $Credential
    if (-not(Get-Item -Path 'X:\index.html')) {
        Remove-Item -Path "X:\" -Recurse -Force
        Copy-Item -Verbose -Path "C:\Temp\index.html" -Destination "X:\" -Force
    }
    Remove-PSDrive -Name X -Force
}