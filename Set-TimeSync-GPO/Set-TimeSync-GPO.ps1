# Run this script as Administrator to permanently configure Windows Time Sync via Local GPO

Write-Host "`n===== Enforcing Windows Time Synchronization via Local GPO =====`n"

# 1️⃣ Ensure Windows Time Service is Enabled and Set to Auto Start
Write-Host "🔄 Ensuring Windows Time Service (W32Time) is enabled..."
sc config w32time start= auto
net stop w32time
net start w32time

# 2️⃣ Set Local Group Policy for Windows Time Service
Write-Host "🔧 Configuring Local GPO to Force Time Sync..."

# Enable Windows NTP Client (GPO Equivalent)
reg add "HKLM\Software\Policies\Microsoft\W32Time\TimeProviders\NtpClient" `
    /v "Enabled" /t REG_DWORD /d 1 /f

# Set Preferred NTP Servers
reg add "HKLM\Software\Policies\Microsoft\W32Time\Parameters" `
    /v "NtpServer" /t REG_SZ `
    /d "time.windows.com,0x8 pool.ntp.org,0x8" /f

# Force Sync Interval to 1 Hour (instead of default 7 days)
reg add "HKLM\Software\Policies\Microsoft\W32Time\TimeProviders\NtpClient" `
    /v "SpecialPollInterval" /t REG_DWORD /d 3600 /f

# Set Time Sync Type to NTP
reg add "HKLM\Software\Policies\Microsoft\W32Time\Parameters" `
    /v "Type" /t REG_SZ /d "NTP" /f

# Force Windows to sync from manual NTP list
reg add "HKLM\Software\Policies\Microsoft\W32Time\Config" `
    /v "SyncFromFlags" /t REG_DWORD /d 1 /f

# 3️⃣ Force Immediate Sync
Write-Host "⏳ Forcing immediate time synchronization..."
w32tm /config `
    /manualpeerlist:"time.windows.com,0x8 pool.ntp.org,0x8" `
    /syncfromflags:manual /update
w32tm /resync /force

# 4️⃣ Verify Sync Status
Write-Host "`n===== Time Sync Status =====`n"
w32tm /query /status

Write-Host "`n✅ Windows Time Sync is now permanently enforced via Local GPO!`n"
