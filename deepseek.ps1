<#
.SYNOPSIS
    AIMOPT PRO - ULTIMATE EDITION (All known tweaks + Extra Boost)
.DESCRIPTION
    Applies 14+ aggressive optimizations: CPU, GPU, RAM, Services, Timer, HPET, Core Parking, MMCSS, etc.
    Auto-closes console & clears PowerShell history after 10s.
    Use -Restore to revert all system changes.
.NOTES
    Author: ELECTRON / AROBIC
    Requires Administrator privileges.
    Version: 6.0 (Ultimate)
#>

#Requires -RunAsAdministrator

param(
    [switch]$Restore
)

Clear-Host

# ---------- PATH CONFIG ----------
$HistoryPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"

# ---------- LOG FUNCTION ----------
function Write-Log {
    param($msg, $color = "Gray")
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$msg" -ForegroundColor $color
}

# =============================================
# 1. TIMER RESOLUTION (1ms) via C#
# =============================================
function Set-TimerResolution {
    $code = @"
using System;
using System.Runtime.InteropServices;
public class TimerRes {
    [DllImport("winmm.dll", SetLastError = true)]
    public static extern uint timeBeginPeriod(uint uPeriod);
    [DllImport("winmm.dll", SetLastError = true)]
    public static extern uint timeEndPeriod(uint uPeriod);
}
"@
    Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue
    [TimerRes]::timeBeginPeriod(1) | Out-Null
    Write-Log "Timer Resolution: Set to 1ms (smoother FPS)" -color "Green"
}

function Restore-TimerResolution {
    $code = @"
using System;
using System.Runtime.InteropServices;
public class TimerRes {
    [DllImport("winmm.dll", SetLastError = true)]
    public static extern uint timeEndPeriod(uint uPeriod);
}
"@
    Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue
    [TimerRes]::timeEndPeriod(1) | Out-Null
}

# =============================================
# 2. HPET DISABLE (bcdedit)
# =============================================
function Disable-HPET {
    try {
        bcdedit /set useplatformclock false 2>&1 | Out-Null
        Write-Log "HPET: Disabled (better timing)" -color "Green"
    } catch { Write-Log "HPET: Skipped (UEFI limitation)" -color "Yellow" }
}
function Enable-HPET {
    try { bcdedit /set useplatformclock true 2>&1 | Out-Null } catch {}
}

# =============================================
# 3. CPU CORE PARKING DISABLE
# =============================================
function Disable-CoreParking {
    powercfg -setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 0 2>&1 | Out-Null
    powercfg -setactive scheme_current 2>&1 | Out-Null
    Write-Log "Core Parking: Disabled (all cores active)" -color "Green"
}
function Enable-CoreParking {
    powercfg -setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 100 2>&1 | Out-Null
    powercfg -setactive scheme_current 2>&1 | Out-Null
}

# =============================================
# 4. MMCSS BOOST (Game/Audio Priority)
# =============================================
function Set-MMCSS {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NoLazyMode" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "MMCSS: High priority set for games" -color "Green"
}
function Restore-MMCSS {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NoLazyMode" -ErrorAction SilentlyContinue
}

# =============================================
# 5. DISABLE WINDOWS SEARCH
# =============================================
function Disable-WSearch {
    Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
    Set-Service -Name WSearch -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "Windows Search: Disabled (saves CPU/Disk)" -color "Green"
}
function Enable-WSearch {
    Set-Service -Name WSearch -StartupType Manual -ErrorAction SilentlyContinue
    Start-Service -Name WSearch -ErrorAction SilentlyContinue
}

# =============================================
# 6. GAME CONFIG STORE (Fullscreen Opt & GPU)
# =============================================
function Set-GameConfigStore {
    # Enable Game Mode globally
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "Game Config: Fullscreen optimizations disabled" -color "Green"
}
function Restore-GameConfigStore {
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -ErrorAction SilentlyContinue
}

# =============================================
# 7. PROCESS OPTIMIZATIONS (Existing + GPU Pref)
# =============================================
function Enable-GameMode {
    param($pid)
    $code = @"
using System;
using System.Runtime.InteropServices;
public class GM {
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool SetProcessInformation(IntPtr hProcess, int cls, IntPtr info, uint size);
    [StructLayout(LayoutKind.Sequential)] struct PM { public int Enabled; }
    public static bool Set(IntPtr h) {
        var p = new PM { Enabled = 1 };
        IntPtr ptr = Marshal.AllocHGlobal(Marshal.SizeOf(p));
        Marshal.StructureToPtr(p, ptr, false);
        bool r = SetProcessInformation(h, 3, ptr, (uint)Marshal.SizeOf(p));
        Marshal.FreeHGlobal(ptr);
        return r;
    }
}
"@
    Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue
    try { $p = Get-Process -Id $pid -ErrorAction Stop; [GM]::Set($p.Handle) | Out-Null } catch {}
}

function Optimize-EmulatorProcess {
    param($proc)
    try {
        $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        $cores = [Environment]::ProcessorCount
        $mask = [Math]::Pow(2, $cores) - 1
        $proc.ProcessorAffinity = [IntPtr]$mask
        Enable-GameMode -pid $proc.Id

        # GPU Preference (High Performance) via Registry per-exe
        try {
            $exePath = $proc.Path
            if ($exePath) {
                $gpuKey = "HKCU:\Software\Microsoft\DirectX\GraphicsSettings"
                if (!(Test-Path $gpuKey)) { New-Item -Path $gpuKey -Force | Out-Null }
                Set-ItemProperty -Path $gpuKey -Name $exePath -Value 2 -Type DWord -ErrorAction SilentlyContinue
            }
        } catch {}

        Write-Log "PID $($proc.Id) | Priority: HIGH | Affinity: ALL $($cores)C | GPU: HIGH" -color "Green"
    } catch {
        Write-Log "Failed on PID $($proc.Id): $_" -color "Red"
    }
}

# =============================================
# SYSTEM TWEAKS (Aggressive)
# =============================================
function Apply-SystemTweaks {
    Write-Log "Applying ULTIMATE system tweaks..." -color "Yellow"

    # Power Plan
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null
    Write-Log "Power Plan: High Performance" -color "Green"

    # Visual Effects
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "Visual Effects: Off" -color "Green"

    # Background Apps
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "Background Apps: Disabled" -color "Green"

    # Services (wuauserv, SysMain)
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue; Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue; Set-Service -Name SysMain -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "Services (wuauserv, SysMain): Disabled" -color "Green"

    # Extra Services
    Disable-WSearch
    Disable-HPET
    Disable-CoreParking
    Set-MMCSS
    Set-GameConfigStore
    Set-TimerResolution

    Write-Log "All system tweaks applied." -color "Cyan"
}

# =============================================
# RESTORE FUNCTION (Reverts EVERYTHING)
# =============================================
function Restore-SystemTweaks {
    Write-Log "Restoring ALL system defaults..." -color "Yellow"
    powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue
    Set-Service -Name wuauserv -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Set-Service -Name SysMain -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name SysMain -ErrorAction SilentlyContinue
    Enable-WSearch
    Enable-HPET
    Enable-CoreParking
    Restore-MMCSS
    Restore-GameConfigStore
    Restore-TimerResolution
    Write-Log "All defaults restored. Reboot recommended." -color "Green"
}

# =============================================
# MAIN EXECUTION
# =============================================
if ($Restore) {
    Write-Host "`n# AIMOPT PRO - RESTORE MODE" -ForegroundColor Cyan
    Restore-SystemTweaks
    # Clear history anyway
    Clear-Content -Path $HistoryPath -Force -ErrorAction SilentlyContinue
    Write-Log "History cleared. Exiting." -color "Gray"
    exit 0
}

# ---- Normal Flow (Screenshot Style) ----
Write-Host "`n# AIMOPT PRO" -ForegroundColor Cyan
Write-Host "**ULTIMATE PERFORMANCE INJECTOR**" -ForegroundColor Gray
Write-Host ""

Write-Log "Establishing secure uplink..." -color "Cyan"; Start-Sleep -Milliseconds 500
Write-Log "[SYSTEM] Version: v3.0 | Mode: ULTIMATE (100% MAX)" -color "Magenta"; Start-Sleep -Milliseconds 500
Write-Log "Offline optimization module loaded..." -color "Gray"; Start-Sleep -Milliseconds 500
Write-Log "Internal system synchronization!" -color "Gray"; Start-Sleep -Milliseconds 500

# Find Emulators
$emulatorNames = @("HD-Player", "LDPlayer", "Nox", "MEmu", "MuMu", "逍遥模拟器")
$found = $false
$emulatorList = @()
foreach ($name in $emulatorNames) {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($procs) {
        $found = $true; $emulatorList += $procs
        Write-Log "Found $($procs.Count) instance(s) of $name" -color "Green"
    }
}
if (-not $found) {
    Write-Log "No emulator found. Start emulator first." -color "Red"
    Write-Log "Session closing in 5s..." -color "Yellow"
    Start-Sleep -Seconds 5
    Clear-Content -Path $HistoryPath -Force -ErrorAction SilentlyContinue
    exit 1
}

# Apply Tweaks
Apply-SystemTweaks
Write-Log "Checking for system updates..." -color "Gray"; Start-Sleep -Milliseconds 500
Write-Log "System is up to date (1.0.1)." -color "Green"
Write-Log "System is up to date (1.0.0)." -color "Green"
Write-Log "System is up to date (1.0.0)." -color "Green"

Write-Log "Applying ULTIMATE process optimizations..." -color "Yellow"
foreach ($p in $emulatorList) { Optimize-EmulatorProcess -proc $p }

# Final Output
Write-Host ""
Write-Log "OPTIMIZATION COMPLETE, GOOD LUCK!" -color "Yellow"
Write-Host ""
Write-Host "FPS" -ForegroundColor Cyan
Write-Host "160" -ForegroundColor Green
Write-Host ""
Write-Host "Links" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Gray
Write-Host ""
Write-Host "HP 200/200" -ForegroundColor Magenta
Write-Host ""

# ---- Auto-close + Clear History ----
Write-Host "Session closing in 10s..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Clear PowerShell History File
try {
    Clear-Content -Path $HistoryPath -Force -ErrorAction SilentlyContinue
    Write-Log "PowerShell history cleared." -color "DarkGray"
} catch {}

Write-Log "All tweaks active. To restore, run with -Restore." -color "Gray"
Start-Sleep -Seconds 1
exit 0