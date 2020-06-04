Param (
    [string]$resourceGroupname,
    [string]$storageAccountName,
    [string[]]$fileShareNames,
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


# Getting / setting inputs
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


Write-Output "====================================================================================" 
foreach ($fileShareName in $fileShareNames) {
    #Create Snapshot
    try {
        $share = Get-AzStorageShare -Context $storageAcct.Context -Name $fileShareName
        "Creating snapshot...   [ snapshot Name : $($share.Name) ]"
        $snapshot = $share.Snapshot()
    }
    catch {
        if (!$snapshot) {
            $ErrorMessage = "Snapshot [$($share.Name)] creation failed."
            throw $ErrorMessage
        }
        else {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
 
    # Generate Snapshot List
    $allSnapshots = Get-AzStorageShare -Context $storageAcct.Context | Where-Object {$_.Name -eq $fileShareName -and $_.IsSnapshot -eq $true}
 
    $count = 0
    for ($i = $allSnapshots.Count - 1; $i -ge 0 ; $i--) {
        $currentSnapshot = $allSnapshots[$i]
        if ($currentSnapshot.Name -like"$diskName*") {
            $count++
 
            #Delete Snapshot
            try {
                if ($count -gt $retention) {
                    "Removing...   [ creation Time : $($currentSnapshot.SnapshotTime) ]"
                    $removeBehavior = Remove-AzStorageShare -Share $currentSnapshot -Force
                }
            }
            catch {
                if (!$removeBehavior) {
                    $ErrorMessage = "Deleting snapshot [$($currentSnapshot.Name)] failed."
                    throw $ErrorMessage
                }
                else {
                    Write-Error -Message $_.Exception
                    throw $_.Exception
                }
            }
        }
    }
}
