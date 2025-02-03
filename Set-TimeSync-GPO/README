# Windows Time Synchronization - Local GPO Enforcement
This script (`Set-TimeSync-GPO.ps1`) permanently forces Windows to sync time correctly
by applying **Local Group Policy (GPO) settings via Registry modifications**.

## Why is this Needed?
- Windows sometimes **fails to sync time properly** and falls back to an unreliable CMOS clock.
- Some systems have **delayed synchronization (default is once every 7 days)**.
- Using **Local GPO settings ensures permanent enforcement** of time sync policies.

## What This Script Does:
1. **Forces Windows Time Service (W32Time) to always start automatically**.
2. **Applies Local Group Policy (GPO) settings via Registry**:
   - **Enables the Windows NTP Client**.
   - **Forces use of `time.windows.com` & `pool.ntp.org`**.
   - **Sets the sync interval to 1 hour** (instead of the default 7 days).
   - **Ensures Windows only syncs with these servers**.
3. **Forces an immediate synchronization**.
4. **Verifies the time sync status**.

## How to Run the Script:
1. Open **PowerShell as Administrator**.
2. Run the script:
