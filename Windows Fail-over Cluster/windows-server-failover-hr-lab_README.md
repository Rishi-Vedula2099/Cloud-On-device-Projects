# Windows Server Failover Cluster POC — HR Workload (`HRCluster`)

Proof-of-concept high-availability lab built on Hyper-V (`corp.hr.local`) implementing a two-node Windows Server Failover Cluster (`HRCluster`), centralized iSCSI shared storage on `STORAGE01`, a clustered, continuously available SMB file share (`\\HRAPPROLE\HRDocs$`), failover validation, and optional Windows Network Load Balancing (NLB) for HTTP traffic distribution.

## Architecture Overview

- **Hyper-V Host (`DESKTOP-NVBB8P4` — `192.168.77.1`):** Runs `DC01`, `STORAGE01`, `HV-NODE1`, and `HV-NODE2` on `LabInternalSwitch`.
- **Active Directory & DNS (`DC01` — `192.168.77.10`):** Domain `corp.hr.local` with `A` records for cluster nodes, `HRCluster` (`192.168.77.50`), and `HRAppRole` (`192.168.77.51`).
- **Shared iSCSI Storage (`STORAGE01` / `WIN-SCPVGL8HT6C` — `192.168.77.20`):** Exposes `Quorum.vhdx` (~9 GB) and `HRData.vhdx` (~48 GB) via iSCSI Target (`HRClusterTarget`).
- **Failover Cluster (`HRCluster` — `192.168.77.50`):** Two-node cluster (`HV-NODE1` at `192.168.77.31`, `HV-NODE2` at `192.168.77.32`) configured with `Majority` (`NodeAndDiskMajority`) quorum on `Quorum Disk`.
- **Clustered HR Role & Share (`HRAppRole` — `192.168.77.51`):** Owns the shared HR volume (`HR Data Disk` / `E:\`) and serves clustered SMB share `HRDocs$` (`E:\HRDocs`), verified with `onboarding_policy.txt`.

## Repository Structure

```text
windows-server-failover-hr-lab/
├── README.md
├── .gitignore
├── docs/
│   ├── HRCluster_Architecture_and_POC.pdf
│   ├── architecture.md
│   └── validation-results.md
├── scripts/
│   ├── 01-dns-and-iscsi-setup.ps1
│   ├── 02-cluster-create-and-quorum.ps1
│   ├── 03-hr-role-and-smb-share.ps1
│   ├── 04-failover-validation.ps1
│   └── 05-nlb-traffic-distribution.ps1
└── config/
    └── lab-topology.json
```

## IP Allocation Matrix

| Component / Role | Hostname / Resource | IP Address | Notes |
| :--- | :--- | :--- | :--- |
| Hyper-V Host | `DESKTOP-NVBB8P4` | `192.168.77.1` | Internal virtual switch (`LabInternalSwitch`) |
| Domain Controller / DNS | `DC01` | `192.168.77.10` | Domain `corp.hr.local` |
| iSCSI Storage Server | `STORAGE01` (`WIN-SCPVGL8HT6C`) | `192.168.77.20` | Hosts `Quorum.vhdx` (~9 GB) & `HRData.vhdx` (~48 GB) |
| Cluster Node 1 | `HV-NODE1` | `192.168.77.31` | Cluster Node ID 1 |
| Cluster Node 2 | `HV-NODE2` | `192.168.77.32` | Cluster Node ID 2 |
| Cluster Management VIP | `HRCluster` | `192.168.77.50` | Failover Cluster CNO & IP |
| HR Application Role VIP | `HRAppRole` | `192.168.77.51` | Clustered File Server & `HRDocs$` (`E:\HRDocs`) |
| Optional Web NLB VIP | `HRWebLB` | `192.168.77.60` | Active-active HTTP load balancing across nodes |

## Quick Execution Order

1. **`scripts/01-dns-and-iscsi-setup.ps1`** — Verify DNS records on `DC01` and iSCSI virtual disks/targets on `STORAGE01`.
2. **`scripts/02-cluster-create-and-quorum.ps1`** — Validate nodes, create `HRCluster`, attach shared disks, and configure `NodeAndDiskMajority` quorum.
3. **`scripts/03-hr-role-and-smb-share.ps1`** — Provision `HRAppRole` (`192.168.77.51`), assign `HR Data Disk`, and publish continuously available SMB share `HRDocs$`.
4. **`scripts/04-failover-validation.ps1`** — Run controlled role moves (`Move-ClusterGroup`) and unplanned node stop/start tests (`Stop-ClusterNode` / `Start-ClusterNode`).
5. **`scripts/05-nlb-traffic-distribution.ps1`** — Configure Windows NLB + IIS on `192.168.77.60` for active-active web traffic distribution.

## Maintenance & Follow-Up Notes

- Remove residual DNS `A` record `win-bi88h22kqjs` (`192.168.77.10`) in `corp.hr.local`.
- Run `Stop-ClusterNode -Name "HV-NODE1"` without `-Force` when testing unplanned node failure (`Stop-ClusterNode` does not accept `-Force`).
