<#
.SYNOPSIS
    Verifies DNS A records on DC01 and iSCSI virtual disks/targets on STORAGE01.
#>

# --- Run on DC01 (192.168.77.10) ---
Import-Module DnsServer
Get-DnsServerResourceRecord -ZoneName "corp.hr.local" -RRType A | Format-Table -AutoSize

# Optional: Remove stale pre-rename A record if present
Remove-DnsServerResourceRecord -ZoneName "corp.hr.local" -RRType "A" -Name "win-bi88h22kqjs" -Force -ErrorAction SilentlyContinue

# --- Run on STORAGE01 (192.168.77.20) ---
Get-IscsiVirtualDisk
Get-IscsiServerTarget
