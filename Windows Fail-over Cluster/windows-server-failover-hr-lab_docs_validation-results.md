# POC Validation Results & Observations

## 1. DNS Forward Lookup Zone (`corp.hr.local` on `DC01`)

- **Command:** `Get-DnsServerResourceRecord -ZoneName "corp.hr.local" -RRType A`
- **Verified Records:**
  - `@`, `DomainDnsZones`, `ForestDnsZones` -> `192.168.77.10`
  - `WIN-SCPVGL8HT6C` (`STORAGE01`) -> `192.168.77.20`
  - `HV-NODE1` -> `192.168.77.31`
  - `HV-NODE2` -> `192.168.77.32`
  - `HRCluster` -> `192.168.77.50`
  - `HRAppRole` -> `192.168.77.51`
- **Hygiene Finding:** Stale `A` record `win-bi88h22kqjs` (`192.168.77.10`) remains from pre-rename setup and should be removed.

## 2. iSCSI Virtual Disks (`STORAGE01` / `WIN-SCPVGL8HT6C`)

- **Command:** `Get-IscsiVirtualDisk; Get-IscsiServerTarget`
- **Result:** Passed. Both `F:\iSCSIVirtualDisks\Quorum.vhdx` (`9663676416` bytes, `Connected`) and `E:\iSCSIVirtualDisks\HRData.vhdx` (`51539607552` bytes, `Connected`) are actively served.

## 3. Cluster & Quorum Health (`HRCluster`)

- **Command:** `Get-ClusterNode -Cluster "HRCluster"; Get-ClusterQuorum -Cluster "HRCluster"; Get-ClusterGroup -Cluster "HRCluster"`
- **Result:** Passed.
  - `HV-NODE1`: `Up`
  - `HV-NODE2`: `Up`
  - `QuorumResource`: `Quorum Disk` (`QuorumType : Majority`)
  - `HRAppRole`: `Online` on `HV-NODE1`
  - `Cluster Group`: `Online` on `HV-NODE2`

## 4. Clustered SMB Share (`HRDocs$`)

- **Command:** `Get-SmbShare -Name "HRDocs$"; Test-Path "\\192.168.77.51\HRDocs$"; Get-ChildItem -Path "E:\HRDocs"`
- **Result:** Passed.
  - `ScopeName`: `HRAPPROLE`, `Path`: `E:\HRDocs`, `ContinuouslyAvailable`: `True`
  - `Test-Path "\\192.168.77.51\HRDocs$"` returned `True`
  - `onboarding_policy.txt` (`40` bytes) verified on shared storage

## 5. Controlled Failover (`Move-ClusterGroup`)

- **Command:** `Move-ClusterGroup -Cluster "HRCluster" -Name "HRAppRole" -Node "HV-NODE2"; Get-ClusterGroup -Cluster "HRCluster" -Name "HRAppRole"; Move-ClusterGroup -Cluster "HRCluster" -Name "HRAppRole" -Node "HV-NODE1"; Get-ClusterGroup -Cluster "HRCluster" -Name "HRAppRole"`
- **Result:** Passed. `HRAppRole` transitioned cleanly to `HV-NODE2` (`Online`) and back to `HV-NODE1` (`Online`).

## 6. Unplanned Failover Test Note (`Stop-ClusterNode`)

- **Observation:** Passing `-Force` to `Stop-ClusterNode` raises `ParameterBindingException` (`A parameter cannot be found that matches parameter name 'Force'`).
- **Corrected Validation Command:**
  ```powershell
  Stop-ClusterNode -Name "HV-NODE1"
  Start-Sleep -Seconds 5
  Get-ClusterGroup -Cluster "HRCluster" -Name "HRAppRole"
  Start-ClusterNode -Name "HV-NODE1"
  Get-ClusterNode -Cluster "HRCluster"
  ```
