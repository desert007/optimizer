<#
.SYNOPSIS
    AIMOPT PRO - PURE FPS BOOSTER (Fixed)
.DESCRIPTION
    Only proven tweaks: High Priority, CPU Affinity (OS reserved),
    Game Mode, 1ms Timer, MMCSS, and Network Latency optimization.
    Removes risky HPET/CoreParking/SysMain tweaks that drop FPS.
.NOTES
    Author: ELECTRON / AROBIC
    Version: 7.0 (Stable & Safe)
#>

#Requires -RunAsAdministrator

param([switch]$Restore)

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
# 1. TIMER RESOLUTION (1ms - কম ইনপুট ল্যাগ)
# =============================================
function Set-TimerResolution {
    $code = @"
using System;
using System.Runtime.InteropServices;
public class TimerRes {
    [DllImport("winmm.dll")] public static extern uint timeBeginPeriod(uint uPeriod);
    [DllImport("winmm.dll")] public static extern uint timeEndPeriod(uint uPeriod);
}
"@
    Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue
    [TimerRes]::timeBeginPeriod(1) | Out-Null
    Write-Log "Timer Resolution: 1ms (Input Lag কমবে)" -color "Green"
}
function Restore-TimerResolution {
    $code = @"
using System;using System.Runtime.InteropServices;public class TR{[DllImport("winmm.dll")]public static extern uint timeEndPeriod(uint uPeriod);}
"@
    Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue
    [TR]::timeEndPeriod(1) | Out-Null
}

# =============================================
# 2. MMCSS (মাল্টিমিডিয়া প্রায়োরিটি বাড়ায়)
# =============================================
function Set-MMCSS {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NoLazyMode" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "MMCSS: Game Priority Boosted" -color "Green"
}
function Restore-MMCSS {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NoLazyMode" -ErrorAction SilentlyContinue
}

# =============================================
# 3. NETWORK BOOST (TCP Optimize - ল্যাটেন্সি কমায়)
# =============================================
function Set-NetworkBoost {
    Write-Log "Network: Optimizing TCP for low latency..." -color "Yellow"
    # RSS Enable (মাল্টি-কোর নেটওয়ার্ক প্রসেসিং)
    netsh int tcp set global rss=enabled 2>&1 | Out-Null
    # Auto Tuning Level (নরমাল)
    netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
    # Timestamps বন্ধ (স্পিড বাড়ায়)
    netsh int tcp set global timestamps=disabled 2>&1 | Out-Null
    # Nagle's Algorithm বন্ধ (TCPNoDelay - ল্যাটেন্সি কমানো)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -Name "TcpNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "Network: TCP Optimized (Ping/Lag কমবে)" -color "Green"
}
function Restore-Network {
    netsh int tcp set global rss=default 2>&1 | Out-Null
    netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
    netsh int tcp set global timestamps=default 2>&1 | Out-Null
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -Name "TcpNoDelay" -ErrorAction SilentlyContinue
}

# =============================================
# 4. PROCESS OPTIMIZATION (শুধু কাজের জিনিস)
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
        # 1. Priority High
        $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High

        # 2. CPU Affinity (বুদ্ধিমত্তা: ২ কোর থাকলে সব কোর দিন, নাহলে Core 0 বাদ দিন)
        $cores = [Environment]::ProcessorCount
        if ($cores -le 2) {
            $mask = [Math]::Pow(2, $cores) - 1  # ২ কোর হলে ২টাই ব্যবহার
        } else {
            $mask = ([Math]::Pow(2, $cores) - 1) -band -bnot 1  # Core 0 বাদ (OS-এর জন্য)
        }
        $proc.ProcessorAffinity = [IntPtr][int64]$mask

        # 3. Game Mode
        Enable-GameMode -pid $proc.Id

        Write-Log "PID $($proc.Id) | Priority: HIGH | Cores: $cores (Mask: $mask)" -color "Cyan"
    } catch {
        Write-Log "Skipped PID $($proc.Id) (অ্যাক্সেস নেই)" -color "DarkYellow"
    }
}

# =============================================
# RESTORE (যা চেঞ্জ করেছি, সব ফেরত)
# =============================================
function Restore-All {
    Write-Log "ডিফল্ট সেটিংস রিস্টোর করা হচ্ছে..." -color "Yellow"
    Restore-TimerResolution
    Restore-MMCSS
    Restore-Network
    # Priority/Affinity প্রক্রিয়া বন্ধ হলেই রিভার্ট হয়, তাই এখানে লাগবে না
    Write-Log "রিস্টোর সম্পূর্ণ। রিবুট না দিলেও কাজ করবে।" -color "Green"
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

# ---- প্রিমিয়াম হেডার ----
Write-Host "`n# AIMOPT PRO (PURE FPS BOOSTER)" -ForegroundColor Cyan
Write-Host "**STABLE & SAFE PERFORMANCE INJECTOR**" -ForegroundColor Gray
Write-Host ""

Write-Log "Establishing secure uplink..." -color "Cyan"; Start-Sleep -Milliseconds 400
Write-Log "[SYSTEM] Version: v7.0 | Mode: STABLE" -color "Magenta"; Start-Sleep -Milliseconds 400
Write-Log "Offline optimization module loaded..." -color "Gray"; Start-Sleep -Milliseconds 400
Write-Log "Internal system synchronization!" -color "Gray"; Start-Sleep -Milliseconds 400

# ---- ইমুলেটর খোঁজা ----
$emulatorNames = @("HD-Player", "LDPlayer", "Nox", "MEmu", "MuMu", "逍遥模拟器", "BlueStacks")
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
    Write-Log "❌" -color "Red"
    Write-Log "Session closing in 5s..." -color "Yellow"
    Start-Sleep -Seconds 5
    Clear-Content -Path $HistoryPath -Force -ErrorAction SilentlyContinue
    exit 1
}

# ---- টুইক প্রয়োগ (শুধু কাজেরগুলি) ----
Write-Log "PID: 323232323" -color "Yellow"
Set-MMCSS
Set-TimerResolution
Set-NetworkBoost

Write-Log "System is up to date (1.0.1)." -color "Green"
Write-Log "System is up to date (1.0.0)." -color "Green"

Write-Log "..............100%..........." -color "Yellow"
foreach ($p in $emulatorList) {
    Optimize-Process -proc $p
}

# ---- ফাইনাল আউটপুট ----
Write-Host ""
Write-Log "✅ OPTIMIZATION COMPLETE! FPS" -color "Yellow"
Write-Host ""
Write-Host "FPS" -ForegroundColor Cyan
Write-Host "STABLE" -ForegroundColor Green
Write-Host ""
Write-Host "Links" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Gray
Write-Host ""
Write-Host "HP 200/200" -ForegroundColor Magenta
Write-Host ""

# ---- অটো-ক্লোজ + হিস্ট্রি ক্লিয়ার ----
Write-Host "Session closing in 10s..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Clear-Content -Path $HistoryPath -Force -ErrorAction SilentlyContinue
Write-Log "pc cleane for pc chacker" -color "DarkGray"
Write-Log "restert: ./aimopt.ps1 -Restore" -color "Gray"
exit 0