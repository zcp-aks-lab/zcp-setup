Param (
    [string]$resourceGroupname,
    [string]$storageAccountName,
    [int32]$retention
)

#Login section
"Logging in..."
$connectionName ="AzureRunAsConnection"
try {
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage ="Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Create Snapshot
try {
    $storageAcct = Get-AzStorageAccount -ResourceGroupname $resourceGroupname -Name $storageAccountName
}
catch {
    if (!$storageAcct) {
        $ErrorMessage = "Storage Account [$storageAcct] not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$shares = Get-AzStorageShare -Context $storageAcct.Context -Name $fileShareName
foreach ($name in $shares.Name) {
    $share = Get-AzStorageShare -Context $storageAcct.Context -Name $name
    "Creating snapshot...   [ snapshot Name : $($share.Name) ]"
    $snapshot = $share.Snapshot()

    # Generate Snapshot List
    $allSnapshots = Get-AzStorageShare -Context $storageAcct.Context | Where-Object {$_.Name -eq $name -and $_.IsSnapshot -eq $true}

    $count = 0
    for ($i = $allSnapshots.Count - 1; $i -ge 0 ; $i--) {
        $currentSnapshot = $allSnapshots[$i]
        if ($currentSnapshot.Name -like"$diskName*") {
            $count++
            if ($count -gt $retention) {
                echo "Removing...   [ creation Time : $($currentSnapshot.SnapshotTime) ]"
                Remove-AzStorageShare -Share $currentSnapshot -Force
            }
        }
    }
}

