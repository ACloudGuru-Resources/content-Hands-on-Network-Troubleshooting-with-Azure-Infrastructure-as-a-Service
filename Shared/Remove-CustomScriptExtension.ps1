param (
    $VMName
)
Remove-AzVMCustomScriptExtension -ResourceGroupName (Get-AzResourceGroup).ResourceGroupName -VMName "$($VMName)" -Name '$($VMName)-cse' -Force