<#
.SYNOPSIS
    Configures Windows Network Load Balancing (NLB) + IIS across HV-NODE1 and HV-NODE2
    to distribute HTTP traffic behind VIP 192.168.77.60.
#>

# 1. Run on BOTH HV-NODE1 and HV-NODE2
Install-WindowsFeature -Name NLB, Web-Server -IncludeManagementTools

# 2. Run on HV-NODE1 to initialize NLB cluster
New-NlbCluster -InterfaceName "Ethernet" `
    -ClusterName "HRWebLB.corp.hr.local" `
    -ClusterPrimaryIP "192.168.77.60" `
    -SubnetMask "255.255.255.0" `
    -OperationMode "Unicast"

# 3. Run on HV-NODE2 to join NLB cluster
Add-NlbClusterNode -InterfaceName "Ethernet" -NewNodeName "HV-NODE2" -NewNodeInterface "Ethernet"

# 4. Run on DC01 to register DNS A record
# Add-DnsServerResourceRecordA -ZoneName "corp.hr.local" -Name "HRWebLB" -IPv4Address "192.168.77.60"

# 5. Verify NLB Convergence & Failover Draining
Get-NlbClusterNode
# Stop-NlbClusterNode -HostName "HV-NODE1"
# Start-NlbClusterNode -HostName "HV-NODE1"
