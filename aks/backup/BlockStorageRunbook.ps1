Param
(
    [Parameter(Mandatory = $true, HelpMessage ='Storage Location for the managed disk snapshots')]
    [String]
    $resourceGroupName,
    [Parameter(Mandatory = $true, HelpMessage ='Retention for the managed disk snapshots')]
    [Int32]
    $retention
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
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

"Getting / setting inputs..."
$date = (Get-Date).AddHours(9)
#where 절로 tag 확인
$disks = Get-AzDisk | Where-Object {$_.tags["Snapshot"] -eq "True"}

# foreach 조정으로 검색범위 좁히기
foreach ($disk in $disks) {
    $snapshotName = $disk.Name + "-" + $date.ToString("yyyyMMdd-HHmmss")

    $snapshotConfig = New-AzSnapshotConfig `
        -SourceResourceId $disk.Id -Location $disk.Location -SkuName Standard_LRS `
        -CreateOption copy -Tag @{createdOn ="$date"; diskName =$disk.Name}
    
    #Create Snapshot
    "Creating snapshot...   [ snapshot Name : $($snapshotName) ]"
    try {
        $snapshot = New-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName -Snapshot $snapshotConfig
    }
    catch {
        if (!$snapshot) {
            $ErrorMessage = "Snapshot [$snapshotName] creation failed."
            throw $ErrorMessage
        }
        else {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }

    
    "Remove old snapshots..."
    # 생성한 snapshot의 disk로 변경
    $allSnapshots = Get-AzSnapshot -ResourceGroupName $resourceGroupName | Where-Object {$_.tags["diskName"] -eq $disk.Name}
    
    $count = 0
    for ($i = $allSnapshots.Count - 1; $i -ge 0 ; $i--) {
        $currentSnapshot = $allSnapshots[$i]

        $count++
        if ($count -gt $retention) {
            try {
                echo "Removing... $($currentSnapshot.Name)"
                $removeBehavior = Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $currentSnapshot.Name -Force
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
