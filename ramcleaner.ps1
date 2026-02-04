#####################################################
#               Rammap Initialization               #
#####################################################

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$scriptUrl = "https://raw.githubusercontent.com/nabilhasan01/random-windows-scripts/refs/heads/main/ramcleaner.ps1"

if (-not $isAdmin) {
    Write-Host "Requesting Administrative privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm $scriptUrl | iex`"" -Verb RunAs
    exit
}

$url = "https://download.sysinternals.com/files/RAMMap.zip"
$Path = [Environment]::GetEnvironmentVariable("Path", "Machine")
$destDir = "C:\Program Files\RAMMap"
$zipFile = "$destDir\RAMMap.zip"

try {
    if (-not (Test-Path $destDir)) { 
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null 
    }

    Invoke-RestMethod -Uri $url -OutFile $zipFile
    Expand-Archive -Path $zipFile -DestinationPath $destDir -Force
    Remove-Item -Path $zipFile -Force
    
    $pathList = $Path -split ";"
    if ($pathList -notcontains $destDir) {
        $updatedPath = "$Path;$destDir"
        [Environment]::SetEnvironmentVariable("Path", $updatedPath, "Machine")
        $env:Path += ";$destDir"

        Write-Host "Successfully added $destDir to the System PATH." -ForegroundColor Green
    } else {
        Write-Host "$destDir is already in the PATH." -ForegroundColor Yellow
    }

    New-Item -Path "HKCU:\Software\Sysinternals\RAMMap" -Force | Out-Null
    New-ItemProperty -Path "HKCU:\Software\Sysinternals\RAMMap" -Name "EulaAccepted" -Value 1 -PropertyType DWord -Force | Out-Null
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
}

#######################################################
#               Ram Auto Cleanup Script               #
#######################################################

$autoScriptDir = "C:\Users\Public\Scripts"
$autoScriptPath = Join-Path $autoScriptDir "ram_auto_cleaner.ps1"
$vbsPath = Join-Path $autoScriptDir "silent-script-runner.vbs"

$psContent = @'
$mutexName = "Global\RamMapAutoCleaner_UniqueId_99"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)

if (!$mutex.WaitOne(0, $false)) {
    exit
}

Add-Type -AssemblyName System.Windows.Forms
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -Id $PID).Path)
$notify.BalloonTipTitle = "RamMap Auto-Cleaner"
$notify.BalloonTipText = "Background Ram Auto-Cleaner Initialized"
$notify.Visible = $true
$notify.ShowBalloonTip(5000)

$notify.BalloonTipText = "Ram Cleared"
$interval = 1800

try {
    while ($true) {
        Start-Sleep -Seconds $interval
        rammap -Ew
        $notify.ShowBalloonTip(2500)
    }
}
finally {
    # Release Mutex if script ends gracefully (optional, OS handles this on process death)
    $mutex.ReleaseMutex()
    $notify.Dispose()
}
'@

$vbsContent = "Set WshShell = CreateObject(`"WScript.Shell`")`r`n" + `
              "WshShell.Run `"powershell.exe -ExecutionPolicy Bypass -File `"`"$autoScriptPath`"`" `", 0, False"

try {
    if (-not (Test-Path $autoScriptDir)) {
        New-Item -Path $autoScriptDir -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $autoScriptPath -Value $psContent -Force
    Set-Content -Path $vbsPath -Value $vbsContent -Force

    Write-Host "Successfully saved background scripts to $autoScriptDir" -ForegroundColor Green
}
catch {
    Write-Error "Failed to save background scripts: $($_.Exception.Message)"
}

#######################################################
#              Clean Old Instances                    #
#######################################################

$taskName = "Ram Auto Cleaner"
Write-Host "Checking for existing background instances..." -ForegroundColor Cyan

$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
}

$runningScripts = Get-CimInstance Win32_Process | Where-Object { 
    $_.Name -eq 'powershell.exe' -and $_.CommandLine -like "*$autoScriptPath*" 
}

foreach ($proc in $runningScripts) {
    try {
        Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped old instance (PID: $($proc.ProcessId))" -ForegroundColor Yellow
    } catch {
        Write-Warning "Could not stop process $($proc.ProcessId)"
    }
}

####################################################
#               Task Scheduler Logic               #
####################################################

$taskPath = "\"
$description = "Rammap Auto Cleaner by Ghos1y"
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$vbsPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -RunLevel Highest

try {
    Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Description $description -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
    Write-Host "Task Scheduler: '$taskName' created successfully." -ForegroundColor Green
    Start-ScheduledTask -TaskName $taskName
}
catch {
    Write-Error "Failed to register Scheduled Task: $($_.Exception.Message)"
}