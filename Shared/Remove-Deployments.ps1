Connect-AzAccount -Identity
Get-AzResourceGroupDeployment (Get-AzResourceGroup).ResourceGroupName | Remove-AzResourceGroupDeployment -ErrorAction SilentlyContinue