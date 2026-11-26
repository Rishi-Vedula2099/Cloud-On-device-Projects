# Detailed System Architecture — `HRCluster`

## 1. Logical & Physical Topology

```text
+-----------------------------------------------------------------------+
| Hyper-V Host: DESKTOP-NVBB8P4 (192.168.77.1 via LabInternalSwitch)    |
|                                                                       |
|  +-----------------------+              +---------------------------+  |
|  | DC01 (192.168.77.10)  |              | STORAGE01                 |  |
|  | AD DS & DNS           |              | (WIN-SCPVGL8HT6C)         |  |
|  | Zone: corp.hr.local   |              | 192.168.77.20             |  |
|  +-----------+-----------+              | - Quorum.vhdx (~9 GB)     |  |
|              |                          | - HRData.vhdx (~48 GB)    |  |
|              | DNS & Kerberos Auth      +-------------+-------------+  |
|              v                                         | iSCSI Block   |
|  +-----------------------+  Cluster / Role VIPs     | Storage       |
|  | HV-NODE1              |  - HRCluster: .77.50     |               |
|  | 192.168.77.31 (Up)    |  - HRAppRole: .77.51     |               |
|  | Active Owner:         +------------------------+               |
|  | HRAppRole / E:\HRDocs |                          |               |
|  +-----------+-----------+                          |               |
|              ^                                         |               |
|              | Failover Cluster Heartbeat & Storage    |               |
|              v                                         v               |
|  +-----------------------+              +---------------------------+  |
|  | HV-NODE2              |<------------>| Shared LUNs via iSCSI     |  |
|  | 192.168.77.32 (Up)    |              | Initiator (Connected)     |  |
|  | Stand-by / Target     |              +---------------------------+  |
|  +-----------------------+                                              |
+-----------------------------------------------------------------------+
```

## 2. Virtual Machine Resource Allocation (`DESKTOP-NVBB8P4`)

| VM Name | Role | Assigned Memory | IPv4 Address | State |
| :--- | :--- | :--- | :--- | :--- |
| `DC01` | Active Directory Domain Services & DNS | 1980 MB | `192.168.77.10` | Running |
| `STORAGE01` (`WIN-SCPVGL8HT6C`) | iSCSI Target Server | 1628 MB | `192.168.77.20` | Running |
| `HV-NODE1` | Failover Cluster Node 1 | 2126 MB | `192.168.77.31` | Running |
| `HV-NODE2` | Failover Cluster Node 2 | 1930 MB | `192.168.77.32` | Running |

## 3. Shared Storage & Quorum Design

- **Quorum Configuration (`NodeAndDiskMajority`):**
  - **Backing VHDX:** `F:\iSCSIVirtualDisks\Quorum.vhdx` on `STORAGE01`
  - **Size:** `9,663,676,416` bytes (~9 GB)
  - **Serial Number:** `251E9A3E-F2C0-4F65-AC42-C82132F88859`
  - **Cluster Resource:** `Quorum Disk` (`Majority` quorum mode, providing 3 total votes across 2 nodes + 1 witness disk)
- **HR Application Storage:**
  - **Backing VHDX:** `E:\iSCSIVirtualDisks\HRData.vhdx` on `STORAGE01`
  - **Size:** `51,539,607,552` bytes (~48 GB)
  - **Serial Number:** `308ACB9C-75E7-4C79-BE71-2ACAD5F56609`
  - **Cluster Resource:** `HR Data Disk` mounted as `E:\` on the active owner of `HRAppRole`

## 4. High Availability & Load Distribution Model

1. **Stateful File Storage (`HRAppRole` — Active-Passive):**
   - Block-level NTFS storage (`E:\`) is mounted exclusively by the active owner node (`HV-NODE1` or `HV-NODE2`) via SCSI-3 Persistent Reservations.
   - Clients access `\\HRAPPROLE\HRDocs$` (`192.168.77.51`) with `ContinuouslyAvailable = True` (SMB Transparent Failover).
2. **Stateless Web / API Tier (`HRWebLB` — Active-Active via NLB):**
   - Windows Network Load Balancing distributes incoming HTTP requests across `HV-NODE1` (`192.168.77.31`) and `HV-NODE2` (`192.168.77.32`) behind VIP `192.168.77.60`, automatically draining failed nodes.
