# ============================================================
#  SSD Refresh & Health Check
#  - Runs chkdsk, full file read pass, SMART counters
#  - Maintains a persistent JSON log on the drive itself
# ============================================================

# ── 1. Check for run as administrator ────────────────────────────
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then try again." -ForegroundColor Yellow
    return
}


# ── 2. Drive Selection ───────────────────────────────────────
$driveLetter = Read-Host "Enter drive letter (e.g. E)"
$driveLetter = ($driveLetter.TrimEnd(':') + ":")
$driveRoot   = $driveLetter + "\"

$vol = Get-PSDrive -Name $driveLetter.TrimEnd(':') -ErrorAction SilentlyContinue
if (-not $vol) {
    Write-Host "Drive $driveLetter not found." -ForegroundColor Red
    return
}

# ── 3. Helper: Snapshot Drive Space ─────────────────────────
function Get-SpaceSnapshot {
    param([string]$Letter)
    $v = Get-PSDrive -Name $Letter.TrimEnd(':') -ErrorAction SilentlyContinue
    if (-not $v) { return $null }
    return [PSCustomObject]@{
        TotalGB = [math]::Round((($v.Used + $v.Free) / 1GB), 2)
        UsedGB  = [math]::Round(($v.Used  / 1GB), 2)
        FreeGB  = [math]::Round(($v.Free  / 1GB), 2)
    }
}

function Show-SpaceSnapshot {
    param([PSCustomObject]$Snap, [string]$Label)
    Write-Host "$Label" -ForegroundColor Yellow
    Write-Host "  Total: $($Snap.TotalGB) GB"
    Write-Host "  Used : $($Snap.UsedGB) GB"
    Write-Host "  Free : $($Snap.FreeGB) GB"
    Write-Host ""
}

# ── 4. Log File Check / Creation ────────────────────────────
$logPath    = Join-Path $driveRoot "ssd_refresh_log.json"
$logEntries = @()

if (Test-Path $logPath) {
    try {
        $logEntries = Get-Content $logPath -Raw | ConvertFrom-Json
        # Ensure it's always an array even if the file has a single entry
        if ($logEntries -isnot [System.Array]) {
            $logEntries = @($logEntries)
        }

        $lastRun    = $logEntries | Select-Object -Last 1
        $lastDate   = [datetime]$lastRun.StartTime
        $daysAgo    = ([datetime]::Now - $lastDate).Days

        Write-Host "── Previous Run Found ──────────────────────────" -ForegroundColor Cyan
        Write-Host "  Date       : $($lastDate.ToString('yyyy-MM-dd HH:mm:ss'))"
        Write-Host "  Days ago   : $daysAgo"
        Write-Host "  Files read : $($lastRun.FilesRead)"
        Write-Host "  Bytes read : $([math]::Round($lastRun.TotalBytesRead / 1GB, 2)) GB"
        Write-Host "  Read errors: $($lastRun.FailedFiles.Count)"

        if ($lastRun.FailedFiles.Count -gt 0) {
            Write-Host "  Failed files from last run:" -ForegroundColor Red
            $lastRun.FailedFiles | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        }

        Write-Host ""
        $confirm = Read-Host "Run a new refresh pass? (recommend once a year stored at room temp (68-77 deg F), or 6 months if stored at higher than room temp) (Y/N)"
        if ($confirm.ToUpper() -ne 'Y') {
            Write-Host "Exiting without running a new pass." -ForegroundColor Yellow
            return
        }
        Write-Host ""

    } catch {
        Write-Warning "Could not read existing log file: $($_.Exception.Message)"
        Write-Warning "A new log will be created."
        $logEntries = @()
    }
} else {
    Write-Host "No existing log found on $driveLetter - a new log will be created after this run." -ForegroundColor Cyan
    Write-Host ""
}

# ── 5. Initial Space Snapshot ────────────────────────────────
$spaceBefore = Get-SpaceSnapshot -Letter $driveLetter
Show-SpaceSnapshot -Snap $spaceBefore -Label "Initial space on ${driveLetter}:"

$startTime = Get-Date

# ── 6. CHKDSK ───────────────────────────────────────────────
Write-Host "Running chkdsk (read-only scan)..." -ForegroundColor Cyan
Write-Host "Note: To repair errors, schedule 'chkdsk $driveLetter /f /r' and reboot." -ForegroundColor DarkYellow
Write-Host ""

chkdsk $driveLetter
$chkdskExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "chkdsk exit code: $chkdskExitCode" -ForegroundColor $(if ($chkdskExitCode -eq 0) { 'Green' } else { 'Red' })
Write-Host ""

$spaceAfterChkdsk = Get-SpaceSnapshot -Letter $driveLetter
if (-not $spaceAfterChkdsk) {
    Write-Host "Drive $driveLetter not found after chkdsk." -ForegroundColor Red
    return
}
Show-SpaceSnapshot -Snap $spaceAfterChkdsk -Label "Space on ${driveLetter} after chkdsk:"

# ── 7. SMART / Reliability Counters ─────────────────────────
Write-Host "Reading SMART reliability counters..." -ForegroundColor Cyan

try {
    $partition   = Get-Partition -DriveLetter $driveLetter.TrimEnd(':') -ErrorAction Stop
    $physDisk    = Get-PhysicalDisk | Where-Object {
        (Get-Disk -Number $_.DeviceId -ErrorAction SilentlyContinue).Number -eq $partition.DiskNumber
    } | Select-Object -First 1

    $reliability = $physDisk | Get-StorageReliabilityCounter -ErrorAction Stop

    $smartData = [PSCustomObject]@{
        Wear                    = $reliability.Wear
        Temperature             = $reliability.Temperature
        PowerOnHours            = $reliability.PowerOnHours
        ReadErrorsTotal         = $reliability.ReadErrorsTotal
        ReadErrorsUncorrected   = $reliability.ReadErrorsUncorrected
        WriteErrorsTotal        = $reliability.WriteErrorsTotal
        WriteErrorsUncorrected  = $reliability.WriteErrorsUncorrected
    }

    Write-Host "  Wear level          : $($smartData.Wear)%"
    Write-Host "  Temperature         : $($smartData.Temperature) C"
    Write-Host "  Power-on hours      : $($smartData.PowerOnHours)"
    Write-Host "  Read errors (total) : $($smartData.ReadErrorsTotal)"
    Write-Host "  Read errors (uncorr): $($smartData.ReadErrorsUncorrected)"
    Write-Host "  Write errors (total): $($smartData.WriteErrorsTotal)"
    Write-Host "  Write errors(uncorr): $($smartData.WriteErrorsUncorrected)"

} catch {
    Write-Warning "Could not retrieve SMART data: $($_.Exception.Message)"
    $smartData = $null
}

Write-Host ""

# ── 8. File Read Pass ────────────────────────────────────────
Write-Host "Reading files, please wait..." -ForegroundColor Cyan

$files = Get-ChildItem -Path $driveRoot -Recurse -File -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notlike "*ssd_refresh_log*" }

$totalFiles = $files.Count
if ($totalFiles -eq 0) {
    Write-Host "No files found on $driveLetter." -ForegroundColor Yellow
    return
}

$totalBytes        = ($files | Measure-Object -Property Length -Sum).Sum
if (-not $totalBytes -or $totalBytes -le 0) { $totalBytes = 1 }

$filesProcessed    = 0
$bytesProcessed    = 0
$failedFiles       = @()
$readBuffer        = New-Object byte[] 1MB
$etaThresholdFiles = [math]::Ceiling($totalFiles * 0.05)

foreach ($file in $files) {
    $filesProcessed++
    $bytesProcessed += $file.Length

    $percent = [int](($bytesProcessed / $totalBytes) * 100)
    $status  = ""

    if ($filesProcessed -ge $etaThresholdFiles) {
        $elapsed       = (Get-Date) - $startTime
        $elapsedSec    = [math]::Max($elapsed.TotalSeconds, 1)
        $avgPerByte    = $elapsedSec / [double]$bytesProcessed
        $remainBytes   = $totalBytes - $bytesProcessed
        $eta           = [TimeSpan]::FromSeconds([int]($avgPerByte * $remainBytes))
        $status        = "File $filesProcessed of $totalFiles | ETA: $($eta.ToString())"
    } else {
        $status = "File $filesProcessed of $totalFiles | Estimating speed..."
    }

    Write-Progress `
        -Activity "Reading files on $driveLetter" `
        -Status $status `
        -PercentComplete $percent

    try {
        $fs = [System.IO.File]::Open($file.FullName, 'Open', 'Read', 'Read')
        while ($fs.Read($readBuffer, 0, $readBuffer.Length) -gt 0) { }
        $fs.Close()
    } catch {
        Write-Warning "Failed to read: $($file.FullName) - $($_.Exception.Message)"
        $failedFiles += $file.FullName
    }
}

Write-Progress -Activity "Reading files on $driveLetter" -Completed
Write-Host "Done reading files." -ForegroundColor Green
Write-Host ""

# ── 9. Final Space Snapshot ──────────────────────────────────
$spaceAfter = Get-SpaceSnapshot -Letter $driveLetter
if ($spaceAfter) {
    Show-SpaceSnapshot -Snap $spaceAfter -Label "Final space on ${driveLetter}:"
}

# ── 10. Failed File Summary ───────────────────────────────────
if ($failedFiles.Count -gt 0) {
    Write-Host "── Files That Failed to Read ($($failedFiles.Count)) ──" -ForegroundColor Red
    $failedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host ""
} else {
    Write-Host "No read errors encountered." -ForegroundColor Green
    Write-Host ""
}

# ── 11. Write Log Entry ──────────────────────────────────────
$endTime  = Get-Date
$newEntry = [PSCustomObject]@{
    StartTime      = $startTime.ToString("o")
    EndTime        = $endTime.ToString("o")
    DurationMin    = [math]::Round(($endTime - $startTime).TotalMinutes, 2)
    FilesRead      = $filesProcessed
    TotalBytesRead = $bytesProcessed
    FailedFiles    = $failedFiles
    ChkdskExitCode = $chkdskExitCode
    SpaceBefore    = $spaceBefore
    SpaceAfter     = $spaceAfter
    SMART          = $smartData
}

$logEntries += $newEntry

try {
    $logEntries | ConvertTo-Json -Depth 5 | Set-Content -Path $logPath -Encoding UTF8
    Write-Host "Log saved to $logPath" -ForegroundColor Cyan
} catch {
    Write-Warning "Failed to write log: $($_.Exception.Message)"
}
