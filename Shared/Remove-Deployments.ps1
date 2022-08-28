Install-PackageProvider -Name ‘Nuget’ -MinimumVersion 2.8.5.201 -Force
Install-Module 'Az.Accounts','Az.Compute','Az.Resources' -Force
Connect-AzAccount -Identity
Get-AzResourceGroupDeployment (Get-AzResourceGroup).ResourceGroupName | Remove-AzResourceGroupDeployment -ErrorAction SilentlyContinue