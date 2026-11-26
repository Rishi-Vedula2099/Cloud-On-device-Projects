<#
.SYNOPSIS
    Validates controlled failover (Move-ClusterGroup) and unplanned node outage recovery
    (Stop-ClusterNode / Start-ClusterNode) for HRAppRole.
#>

# 1. Controlled Failover: HV-NODE1 -> HV-NODE2 -> HV-NODE1
Move-ClusterGroup -Cluster "HRCluster" -Name "HRAppRole" -Node "HV-NODE2"
Get-ClusterGroup -Cluster "HRCluster" -Name "HRAppRole"
Test-Path "\\192.168.77.51\HRDocs$"

Move-ClusterGroup -Cluster "HRCluster" -Name "HRAppRole" -Node "HV-NODE1"
Get-ClusterGroup -Cluster "HRCluster" -Name "HRAppRole"
Test-Path "\\192.168.77.51\HRDocs$"

# 2. Unplanned Failover Simulation (Note: Stop-ClusterNode does NOT use -Force)
Stop-ClusterNode -Name "HV-NODE1"
Start-Sleep -Seconds 5
Get-ClusterGroup -Cluster "HRCluster" -Name "HRAppRole"

# 3. Bring HV-NODE1 Back Online
Start-ClusterNode -Name "HV-NODE1"
Get-ClusterNode -Cluster "HRCluster"
