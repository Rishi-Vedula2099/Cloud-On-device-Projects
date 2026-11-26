<#
.SYNOPSIS
    Creates clustered role HRAppRole (192.168.77.51), assigns HR Data Disk,
    and provisions a continuously available clustered SMB share (HRDocs$).
    Run inside HV-NODE1 as CORP\Administrator.
#>

# 1. Create Clustered Role with Static IP
Add-ClusterServerRole -Name "HRAppRole" -StaticAddress "192.168.77.51"

# 2. Move HR Data Disk (~48 GB) into HRAppRole
Get-ClusterResource -Name "HR Data Disk" | Move-ClusterResource -Group "HRAppRole"

# 3. Provision Clustered SMB Share on E:\HRDocs
New-Item -Path "E:\HRDocs" -ItemType Directory -Force
New-SmbShare -Name "HRDocs$" -Path "E:\HRDocs" -FullAccess "CORP\Domain Admins", "CORP\Administrator"

# 4. Write Smoke-Test File and Verify Share Properties
Set-Content -Path "\\HRAPPROLE\HRDocs$\onboarding_policy.txt" -Value "HR Policy v1.0 - Verified on HRCluster"
Get-SmbShare -Name "HRDocs$"
Test-Path "\\192.168.77.51\HRDocs$"
Get-ChildItem -Path "E:\HRDocs"
