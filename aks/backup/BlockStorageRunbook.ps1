Param
(
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
        $ErrorMessage ="Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

"Getting / setting inputs..."
$date = Get-Date 
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
        $snapshot = New-AzSnapshot -ResourceGroupName $disk.ResourceGroupName -SnapshotName $snapshotName -Snapshot $snapshotConfig
        # 생성을 다른 resource group으로 이동
    }
    catch {
        if (!$snapshot) {
            $ErrorMessage ="Snapshot [$snapshot]creation failed."
            throw $ErrorMessage
        }
        else {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
    
    "Remove old snapshots..."
    # 생성한 snapshot의 disk로 변경
    $allSnapshots = Get-AzSnapshot -ResourceGroupName $disk.ResourceGroupName | Where-Object {$_.tags["diskName"] -eq $disk.Name}
    
    $count = 0
    for ($i = $allSnapshots.Count - 1; $i -ge 0 ; $i--) {
        $currentSnapshot = $allSnapshots[$i]

        $count++
        if ($count -gt $retention) {
            try {
                echo "Removing... $($currentSnapshot.Name)"
                $removeBehavior = Remove-AzSnapshot -ResourceGroupName $disk.ResourceGroupName -SnapshotName $currentSnapshot.Name -Force
            }
            catch {
                if (!$removeBehavior) {
                    $ErrorMessage ="Deleting snapshot [$removeBehavior] failed."
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