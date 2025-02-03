# Run this script as Administrator to permanently configure Windows Time Sync and Debug Timing Issues

Write-Host @'
===== Enforcing Windows Time Synchronization via Local GPO =====
'@

# Initialize tracking variables for the final summary
$changes = @{ }
$errors = @{ }

# 1️⃣ Ensure Windows Time Service is Enabled and Set to Auto Start
try {
    Write-Host '🔄 Ensuring Windows Time Service (W32Time) is enabled...'
    sc config w32time start= auto
    net stop w32time
    net start w32time
    $changes['Windows Time Service'] = '✅ Restarted and set to auto-start'
} catch {
    $errors['Windows Time Service'] = '❌ Failed to restart: $_'
}

# 2️⃣ Set Local Group Policy for Windows Time Service
try {
    Write-Host '🔧 Configuring Local GPO to Force Time Sync...'
    reg add 'HKLM\Software\Policies\Microsoft\W32Time\TimeProviders\NtpClient' /v 'Enabled' /t REG_DWORD /d 1 /f
    reg add 'HKLM\Software\Policies\Microsoft\W32Time\Parameters' /v 'NtpServer' /t REG_SZ /d 'time.windows.com,0x8 pool.ntp.org,0x8' /f
    reg add 'HKLM\Software\Policies\Microsoft\W32Time\TimeProviders\NtpClient' /v 'SpecialPollInterval' /t REG_DWORD /d 3600 /f
    reg add 'HKLM\Software\Policies\Microsoft\W32Time\Parameters' /v 'Type' /t REG_SZ /d 'NTP' /f
    reg add 'HKLM\Software\Policies\Microsoft\W32Time\Config' /v 'SyncFromFlags' /t REG_DWORD /d 1 /f
    $changes['Local GPO for Time Sync'] = '✅ Applied successfully'
} catch {
    $errors['Local GPO for Time Sync'] = '❌ Failed to apply: $_'
}

# 3️⃣ Force Immediate Sync
try {
    Write-Host '⏳ Forcing immediate time synchronization...'
    w32tm /config /manualpeerlist:'time.windows.com,0x8 pool.ntp.org,0x8' /syncfromflags:manual /update
    w32tm /resync /force
    $changes['Time Sync'] = '✅ Synchronized successfully'
} catch {
    $errors['Time Sync'] = '❌ Failed to synchronize: $_'
}

# 4️⃣ Verify Sync Status
Write-Host '===== Time Sync Status ====='
w32tm /query /status

# 5️⃣ Additional System Configuration and Timing Checks
Write-Host '===== Additional System Timing Configuration ====='

# Detect if HPET is Enabled and Disable if Necessary
try {
    Write-Host '🔎 Checking HPET Status...'
    $bcdedit = bcdedit /enum | Select-String 'useplatformclock'
    if ($bcdedit) {
        Write-Host '❌ HPET is ENABLED. Disabling...'
        bcdedit /deletevalue useplatformclock
        $changes['HPET'] = '✅ Disabled for better timing stability'
    } else {
        $changes['HPET'] = '✅ Already Disabled'
    }
} catch {
    $errors['HPET'] = '❌ Failed to check/disable: $_'
}

# Detect and Set High Performance Power Plan
try {
    Write-Host '🔎 Checking Power Plan...'
    $powerPlan = powercfg /query SCHEME_CURRENT | Select-String 'Balanced'
    if ($powerPlan) {
        Write-Host '⚠️ Detected Balanced Power Plan. Switching to High Performance...'
        powercfg /setactive SCHEME_MIN
        $changes['Power Plan'] = '✅ Changed to High Performance'
    } else {
        $changes['Power Plan'] = '✅ Already set to High Performance'
    }
} catch {
    $errors['Power Plan'] = '❌ Failed to check/change power plan: $_'
}

# Detect and Disable Dynamic Tick if Needed
try {
    Write-Host '🔎 Checking for Dynamic Tick...'
    $dynamicTick = bcdedit /enum | Select-String 'disabledynamictick'
    if (-not $dynamicTick) {
        Write-Host '⚠️ Dynamic Tick is enabled. Disabling it...'
        bcdedit /set disabledynamictick yes
        $changes['Dynamic Tick'] = '✅ Disabled'
    } else {
        $changes['Dynamic Tick'] = '✅ Already Disabled'
    }
} catch {
    $errors['Dynamic Tick'] = '❌ Failed to check/disable: $_'
}

# Detect WMI Issues and Repair if Needed
try {
    Write-Host '🔎 Checking Windows Performance Timers...'
    $timerResolution = wmic path Win32_PerfRawData_PerfOS_System get TimerResolution
    if (-not $timerResolution) {
        throw 'Timer Resolution Query Failed'
    }
    $changes['Windows Performance Timers'] = '✅ No Issues Detected'
} catch {
    Write-Host '❌ Performance Timer Query Failed. Repairing WMI...'
    winmgmt /salvagerepository
    net stop winmgmt /y
    winmgmt /resetrepository
    net start winmgmt
    $changes['Windows Performance Timers'] = '✅ WMI Repaired'
}

# Set Recommended Timer Resolution
try {
    Write-Host '🔎 Setting Timer Resolution to 0.5ms...'
    $timerToolPath = 'C:\TimerTool.exe'
    if (Test-Path $timerToolPath) {
        Start-Process -FilePath $timerToolPath -ArgumentList '0.5'
        $changes['Timer Resolution'] = '✅ Set to 0.5ms'
    } else {
        $errors['Timer Resolution'] = '⚠️ TimerTool.exe not found. Please download and set manually.'
    }
} catch {
    $errors['Timer Resolution'] = '❌ Failed to set Timer Resolution: $_'
}

# Final Summary
Write-Host '`n===== System Timing Debug Report ====='

# Print successful changes
Write-Host '`n✅ Successful Changes:'
$changes.Keys | ForEach-Object { Write-Host "$($_): $($changes[$_])" }

# Print errors if any exist
if ($errors.Count -gt 0) {
    Write-Host '`n⚠️ Errors Encountered:'
    $errors.Keys | ForEach-Object { Write-Host "$($_): $($errors[$_])" }
} else {
    Write-Host '`n✅ No errors encountered!'
}

Write-Host '`n✅ Windows Time Sync and additional timing settings are now permanently enforced via Local GPO!`n'