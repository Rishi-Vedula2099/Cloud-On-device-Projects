<#
.SYNOPSIS
    Validates cluster prerequisites, creates HRCluster, attaches shared iSCSI disks,
    renames disk resources, and configures NodeAndDiskMajority quorum.
    Run inside HV-NODE1 as CORP\Administrator.
#>

$Nodes = @("HV-NODE1.corp.hr.local", "HV-NODE2.corp.hr.local")

# 1. Run Cluster Validation
Test-Cluster -Node $Nodes

# 2. Create Failover Cluster
New-Cluster -Name "HRCluster" -Node $Nodes -StaticAddress "192.168.77.50"

# 3. Add Available Shared Disks
Get-ClusterAvailableDisk | Add-ClusterDisk

# 4. Rename Disk Resources (verify sizes: ~48 GB = HR Data Disk, ~9 GB = Quorum Disk)
(Get-ClusterResource -Name "Cluster Disk 1").Name = "HR Data Disk"
(Get-ClusterResource -Name "Cluster Disk 2").Name = "Quorum Disk"

# 5. Configure Quorum on Quorum Disk
Set-ClusterQuorum -NodeAndDiskMajority "Quorum Disk"

# 6. Verify Cluster State
Get-ClusterNode -Cluster "HRCluster"
Get-ClusterQuorum -Cluster "HRCluster"
Get-ClusterResource -Cluster "HRCluster" | Select-Object Name, State, OwnerGroup, ResourceType
