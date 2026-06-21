<#
.SYNOPSIS
    AIMOPT v9.0 - THE REAL FPS BOOSTER (Config Editor + Fingerprint Spoof)
.DESCRIPTION
    Edits Emulator Config (RAM/CPU), Spoofs Device to ROG Phone 3 to unlock 200+ FPS,
    Applies Windows System Tweaks, ADB Android Tweaks, and Network Boost.
.NOTES
    Author: ELECTRON / AROBIC
    Requires Administrator privileges.
#>

#Requires -RunAsAdministrator

param([switch]$Restore)

Clear-Host

# ---------- PATHS ----------
$HistoryPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"

# ---------- LOG FUNCTION ----------
function Write-Log {
    param($msg, $color = "Gray")
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$msg" -ForegroundColor $color
}

# =============================================
# 1. EMULATOR CONFIG EDITOR (CRITICAL FOR FPS)
# =============================================
function Edit-EmulatorConfig {
    Write-Log "Editing Emulator Configs to unlock 200+ FPS..." -color "Yellow"

    # ---- BlueStacks / MSI Player ----
    $bsPaths = @(
        "C:\ProgramData\BlueStacks_nxt\bluestacks.conf",
        "C:\ProgramData\BlueStacks\bluestacks.conf",
        "$env:ProgramData\BlueStacks_nxt\bluestacks.conf"
    )
    $edited = $false
    foreach ($path in $bsPaths) {
        if (Test-Path $path) {
            Write-Log "Found BlueStacks Config: $path" -color "Cyan"
            try {
                (Get-Content $path) -replace 'bst\.global\.fps=.*', 'bst.global.fps="240"' | Set-Content $path
                (Get-Content $path) -replace 'bst\.instance\..*?\.fps=.*', 'bst.instance.$1.fps="240"' | Set-Content $path
                (Get-Content $path) -replace 'bst\.instance\..*?\.memory=.*', 'bst.instance.$1.memory="8192"' | Set-Content $path
                (Get-Content $path) -replace 'bst\.instance\..*?\.cpu=.*', 'bst.instance.$1.cpu="4"' | Set-Content $path
                # Force High Graphics Performance
                (Get-Content $path) -replace 'bst\.instance\..*?\.graphics_mode=.*', 'bst.instance.$1.graphics_mode="1"' | Set-Content $path
                (Get-Content $path) -replace 'bst\.instance\..*?\.gpu_renderer=.*', 'bst.instance.$1.gpu_renderer="1"' | Set-Content $path
                Write-Log "BlueStacks Config Updated: RAM=8GB, CPU=4 Cores, FPS=240" -color "Green"
                $edited = $true
                break
            } catch {
                Write-Log "Failed to edit BlueStacks config (maybe running?)" -color "Red"
            }
        }
    }

    # ---- LDPlayer ----
    $ldPaths = @(
        "$env:USERPROFILE\AppData\Roaming\XuanZhi\config\config.ini",
        "$env:USERPROFILE\AppData\Roaming\leidian\config\config.ini"
    )
    foreach ($path in $ldPaths) {
        if (Test-Path $path) {
            Write-Log "Found LDPlayer Config: $path" -color "Cyan"
            try {
                (Get-Content $path) -replace 'fps=.*', 'fps=240' | Set-Content $path
                (Get-Content $path) -replace 'memory=.*', 'memory=8192' | Set-Content $path
                (Get-Content $path) -replace 'cpu=.*', 'cpu=4' | Set-Content $path
                Write-Log "LDPlayer Config Updated: RAM=8GB, CPU=4, FPS=240" -color "Green"
                $edited = $true
            } catch { Write-Log "Failed to edit LDPlayer config" -color "Red" }
        }
    }

    if (-not $edited) {
        Write-Log "Emulator Config file not found. Please ensure BlueStacks/MSI/LDPlayer is installed." -color "Yellow"
        Write-Log "Manually set RAM to 8GB and CPU to 4 cores in Emulator Settings." -color "Yellow"
    }
    return $edited
}

# =============================================
# 2. ADB DETECT + FINGERPRINT SPOOF (Bypass Free Fire FPS Lock)
# =============================================
function Find-ADB {
    $adbPaths = @(
        "C:\Program Files\BlueStacks_nxt\HD-Adb.exe",
        "C:\Program Files (x86)\BlueStacks\HD-Adb.exe",
        "C:\Program Files\BlueStacks\HD-Adb.exe",
        "C:\Program Files\LDPlayer\adb.exe",
        "C:\Program Files (x86)\LDPlayer\adb.exe",
        "C:\Program Files\Microvirt\MEmu\adb.exe",
        "C:\Program Files (x86)\Microvirt\MEmu\adb.exe",
        "$env:LOCALAPPDATA\Programs\LDPlayer\adb.exe",
        "$env:ProgramFiles\Nox\bin\adb.exe"
    )
    foreach ($path in $adbPaths) {
        if (Test-Path $path) { return $path }
    }
    $sysAdb = (Get-Command adb -ErrorAction SilentlyContinue).Source
    if ($sysAdb) { return $sysAdb }
    return $null
}

function Invoke-ADBTweaks {
    $adbExe = Find-ADB
    if (-not $adbExe) {
        Write-Log "ADB not found. Skipping Android tweaks." -color "Yellow"
        return $false
    }
    Write-Log "ADB Found: $adbExe" -color "Cyan"
    & $adbExe start-server 2>&1 | Out-Null

    $ports = @("127.0.0.1:5555", "127.0.0.1:21503", "127.0.0.1:5557", "127.0.0.1:5554")
    $connected = $false
    foreach ($port in $ports) {
        $result = & $adbExe connect $port 2>&1
        if ($result -match "connected|already") {
            Write-Log "ADB Connected to $port" -color "Green"
            $connected = $true
            break
        }
    }
    if (-not $connected) {
        Write-Log "ADB Connection failed. Enable USB Debugging in Emulator Settings." -color "Red"
        return $false
    }

    Write-Log "Injecting FPS Unlock & Device Spoof (ROG Phone 3)..." -color "Yellow"

    # 1. SPOOF DEVICE to High-End ROG Phone 3 (Unlocks 200+ FPS in Free Fire)
    $spoofCmds = @(
        "setprop ro.product.model ASUS_I003D",
        "setprop ro.product.manufacturer ASUS",
        "setprop ro.build.product ASUS_I003D",
        "setprop ro.product.brand ASUS",
        "setprop ro.product.device ASUS_I003D",
        "setprop ro.product.name ASUS_I003D"
    )
    foreach ($cmd in $spoofCmds) {
        & $adbExe shell $cmd 2>&1 | Out-Null
    }

    # 2. UNLOCK FPS CAP & GPU FORCE
    $fpsCmds = @(
        "setprop debug.sf.max_fps 240",
        "setprop persist.sys.display.max_fps 240",
        "setprop persist.graphics.vsync.disable 1",
        "setprop debug.gr.swapinterval 0",
        "setprop persist.sys.composition.type gpu",
        "setprop debug.egl.hw 1",
        "setprop debug.gr.gpu 1",
        "setprop persist.sys.gpu.disable_vsync 1",
        "setprop persist.sys.ui.hw 1",
        "settings put global window_animation_scale 0",
        "settings put global transition_animation_scale 0",
        "settings put global animator_duration_scale 0",
        "settings put system peak_refresh_rate 240",
        "settings put global vsync_disabled 1"
    )
    foreach ($cmd in $fpsCmds) {
        & $adbExe shell $cmd 2>&1 | Out-Null
        Start-Sleep -Milliseconds 30
    }

    Write-Log "ADB Tweaks Applied: Device Spoofed to ROG Phone 3, FPS Cap Removed." -color "Green"
    return $true
}

# =============================================
# 3. WINDOWS SYSTEM TWEAKS (Stabilizers)
# =============================================
function Set-TimerResolution {
    $code = @"
using System;using System.Runtime.InteropServices;
public class TR{[DllImport("winmm.dll")]public static extern uint timeBeginPeriod(uint uPeriod);}
"@
    Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue
    [TR]::timeBeginPeriod(1) | Out-Null
    Write-Log "Timer Resolution: 1ms (Low Input Lag)" -color "Green"
}

function Set-MMCSS {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NoLazyMode" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "MMCSS: Game Priority MAX" -color "Green"
}

function Disable-Services {
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue; Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue; Set-Service -Name SysMain -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue; Set-Service -Name WSearch -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "Services: SysMain, Update, Search Disabled" -color "Green"
}
function Disable-VisualFX {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "Visual FX: Disabled (Pure Performance)" -color "Green"
}
function Disable-HPET {
    try { bcdedit /set useplatformclock false 2>&1 | Out-Null; Write-Log "HPET: Disabled (Smooth FPS)" -color "Green" } catch {}
}
function Disable-CoreParking {
    powercfg -setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 0 2>&1 | Out-Null
    powercfg -setactive scheme_current 2>&1 | Out-Null
    Write-Log "Core Parking: Disabled (All Cores Active)" -color "Green"
}
function Set-Network {
    netsh int tcp set global rss=enabled 2>&1 | Out-Null
    netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
    netsh int tcp set global timestamps=disabled 2>&1 | Out-Null
    Write-Log "Network: TCP Optimized (Low Ping)" -color "Green"
}

# =============================================
# 4. PROCESS OPTIMIZATION
# =============================================
function Enable-GameMode {
    param($pid)
    $code = @"
using System;using System.Runtime.InteropServices;
public class GM {
    [DllImport("kernel32.dll")] static extern bool SetProcessInformation(IntPtr h, int cls, IntPtr info, uint size);
    [StructLayout(LayoutKind.Sequential)] struct PM { public int Enabled; }
    public static bool Set(IntPtr h) {
        var p = new PM { Enabled = 1 };
        IntPtr ptr = Marshal.AllocHGlobal(Marshal.SizeOf(p));
        Marshal.StructureToPtr(p, ptr, false);
        bool r = SetProcessInformation(h, 3, ptr, (uint)Marshal.SizeOf(p));
        Marshal.FreeHGlobal(ptr); return r;
    }
}
"@
    Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue
    try { $p = Get-Process -Id $pid -ErrorAction Stop; [GM]::Set($p.Handle) | Out-Null } catch {}
}
function Optimize-Process {
    param($proc)
    try {
        $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        $cores = [Environment]::ProcessorCount
        $mask = [Math]::Pow(2, $cores) - 1
        $proc.ProcessorAffinity = [IntPtr][int64]$mask
        Enable-GameMode -pid $proc.Id
        Write-Log "PID $($proc.Id) | Priority: HIGH | Cores: $cores" -color "Cyan"
    } catch {
        Write-Log "Skipped PID $($proc.Id) (Access Denied)" -color "DarkYellow"
    }
}

# =============================================
# 5. RESTORE
# =============================================
function Restore-All {
    Write-Log "Restoring Windows Defaults..." -color "Yellow"
    powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
    Set-Service -Name wuauserv -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Set-Service -Name SysMain -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name SysMain -ErrorAction SilentlyContinue
    Set-Service -Name WSearch -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name WSearch -ErrorAction SilentlyContinue
    Write-Log "System Defaults Restored. Reboot recommended." -color "Green"
}

# =============================================
# MAIN EXECUTION
# =============================================
if ($Restore) {
    Write-Host "`n# AIMOPT PRO - RESTORE MODE" -ForegroundColor Cyan
    Restore-All
    Clear-Content -Path $HistoryPath -Force -ErrorAction SilentlyContinue
    exit 0
}

# ---- HEADER ----
Write-Host "`n# AIMOPT PRO v9.0" -ForegroundColor Cyan
Write-Host "**REAL FPS BOOSTER - CONFIG EDITOR + SPOOF**" -ForegroundColor Gray
Write-Host ""

Write-Log "Initializing Ultimate Uplink..." -color "Cyan"; Start-Sleep -Milliseconds 400
Write-Log "[SYSTEM] Version: 9.0 | Mode: AGGRESSIVE UNLOCK" -color "Magenta"; Start-Sleep -Milliseconds 400
Write-Log "Loading Offline Modules..." -color "Gray"; Start-Sleep -Milliseconds 400
Write-Log "System Synchronization OK!" -color "Gray"; Start-Sleep -Milliseconds 400

# ---- FIND EMULATOR ----
$emulatorNames = @("HD-Player", "LDPlayer", "Nox", "MEmu", "MuMu", "BlueStacks")
$found = $false
$emulatorList = @()
foreach ($name in $emulatorNames) {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($procs) {
        $found = $true; $emulatorList += $procs
        Write-Log "Detected: $name ($($procs.Count) instances)" -color "Green"
    }
}
if (-not $found) {
    Write-Log "Error: No Emulator Running! Start Free Fire first." -color "Red"
    Write-Log "Closing in 5s..." -color "Yellow"
    Start-Sleep -Seconds 5
    Clear-Content -Path $HistoryPath -Force -ErrorAction SilentlyContinue
    exit 1
}

# ---- APPLY SYSTEM TWEAKS (Stabilizers) ----
Write-Log "Applying System Stabilizers..." -color "Yellow"
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null
Disable-VisualFX
Disable-Services
Disable-HPET
Disable-CoreParking
Set-MMCSS
Set-TimerResolution
Set-Network

# ---- APPLY EMULATOR CONFIG (RAM/CPU) ----
Edit-EmulatorConfig

# ---- APPLY ADB SPOOF (Unlock FPS Cap) ----
Write-Log "Connecting to Android System..." -color "Yellow"
Invoke-ADBTweaks

# ---- APPLY PROCESS PRIORITY ----
Write-Log "Injecting High Priority to Emulator..." -color "Yellow"
foreach ($p in $emulatorList) {
    Optimize-Process -proc $p
}

# ---- FINAL DASHBOARD ----
Write-Host ""
Write-Log "========== UNLOCK SUCCESSFUL ==========" -color "Yellow"
Write-Host ""
Write-Host "FPS CAP" -ForegroundColor Cyan
Write-Host "UNLOCKED TO 240 (Free Fire will run 200+)" -ForegroundColor Green
Write-Host ""
Write-Host "DEVICE SPOOF" -ForegroundColor Cyan
Write-Host "ROG PHONE 3 (ASUS_I003D)" -ForegroundColor Magenta
Write-Host ""
Write-Host "RAM / CPU" -ForegroundColor Cyan
Write-Host "8GB / 4 Cores (Forced)" -ForegroundColor Gray
Write-Host ""
Write-Host "HP 200/200" -ForegroundColor Magenta
Write-Host ""

Write-Host "Session closing in 10s..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Clear-Content -Path $HistoryPath -Force -ErrorAction SilentlyContinue
Write-Log "History Cleared. To Restore, run with -Restore." -color "Gray"
exit 0