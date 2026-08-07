# ==============================================================================
# Steam Downgrade Script
# ==============================================================================
param (
    [string]$ATS = ""
)

$SteamVersions = @(
    [PSCustomObject]@{ Date="20230428150517"; Notes="Around the time new desktop UI released in beta" }
    [PSCustomObject]@{ Date="20230429120402"; Notes="Hotfix" }
    [PSCustomObject]@{ Date="20230531113527"; Notes="Preload banner hotfix, last update before new desktop UI and -oldbigpicture removal" }
    [PSCustomObject]@{ Date="20230615094110"; Notes="Initial new desktop UI version, -oldbigpicture removed" }
    [PSCustomObject]@{ Date="20230616094017"; Notes="Hotfix" }
    [PSCustomObject]@{ Date="20230622105532"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20230711162631"; Notes="Generic notification sounds, fixes, last update before -vgui removal" }
    [PSCustomObject]@{ Date="20230801221717"; Notes="xdg-desktop-portal no longer necessary on Linux, fixes, -vgui removed" }
    [PSCustomObject]@{ Date="20230912101259"; Notes="Indonesian language, fixes, removal of steam://restartinuimode/vgui" }
    [PSCustomObject]@{ Date="20230930002005"; Notes="Hotfix" }
    [PSCustomObject]@{ Date="20231026162438"; Notes="Steam Input and SteamVR improvements, fixes" }
    [PSCustomObject]@{ Date="20231031200154"; Notes="Back button fix, other fixes" }
    [PSCustomObject]@{ Date="20231116205033"; Notes="Visual tweaks, more info in game pages, other fixes and additions" }
    [PSCustomObject]@{ Date="20231130095245"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20231212190321"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20240111223616"; Notes="Workshop upgrades, fixes" }
    [PSCustomObject]@{ Date="20240113112425"; Notes="Fix" }
    [PSCustomObject]@{ Date="20240227211905"; Notes="New Chromium build, fixes" }
    [PSCustomObject]@{ Date="20240229082406"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20240308104109"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20240508075352"; Notes="Fixes, CSS class names changed" }
    [PSCustomObject]@{ Date="20240514121236"; Notes="Fixes, unresponsive on Linux (incomplete?)" }
    [PSCustomObject]@{ Date="20240517103907"; Notes="Steam Input fixes" }
    [PSCustomObject]@{ Date="20240521073345"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20240614090842"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20240619085500"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20240621083816"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20240717082107"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20240913122103"; Notes="Steam Families, fixes" }
    [PSCustomObject]@{ Date="20240918104445"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20241107150153"; Notes="Windows 7/8/8.1, macOS 10.13/10.14 discontinuation, Steam Game Recording, fixes" }
    [PSCustomObject]@{ Date="20241113093224"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20241204072114"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20250123105918"; Notes="Improved game update management, fixes" }
    [PSCustomObject]@{ Date="20250129125321"; Notes="No in-game friend spam when reconnecting, fixes" }
    [PSCustomObject]@{ Date="20250311093241"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20250401193354"; Notes="Download UI update, fixes" }
    [PSCustomObject]@{ Date="20250424082655"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20250429101123"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20250521085614"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20250701090002"; Notes="UI scaling, performance monitor, fixes" }
    [PSCustomObject]@{ Date="20250910074132"; Notes="A ton of additions, fixes" }
    [PSCustomObject]@{ Date="20251003030544"; Notes="Unity vulnerability fix, manual updates broken" }
    [PSCustomObject]@{ Date="20251006072943"; Notes="Re-release" }
    [PSCustomObject]@{ Date="20251118083007"; Notes="Suspicious chat detection, Chromium rebuild adds Google API integration, fixes" }
    [PSCustomObject]@{ Date="20251122131734"; Notes="Hotfix: reverted Google API integration" }
    [PSCustomObject]@{ Date="20251220095344"; Notes="Windows client gets 64-bit support" }
    [PSCustomObject]@{ Date="20260122074724"; Notes="More controller support, fixes" }
    [PSCustomObject]@{ Date="20260310091440"; Notes="Hardware specs in reviews, fixes" }
    [PSCustomObject]@{ Date="20260314103120"; Notes="Rare downloads crash fix, other fixes" }
    [PSCustomObject]@{ Date="20260430114655"; Notes="Low battery level notifs, spell check fix, other fixes" }
    [PSCustomObject]@{ Date="20260506143902"; Notes="Steam Controller support, fixes" }
    [PSCustomObject]@{ Date="20260510115300"; Notes="Fixes" }
    [PSCustomObject]@{ Date="20260523081714"; Notes="Steam Controller charge fix" }
    [PSCustomObject]@{ Date="20260528081318"; Notes="Steam Input/Controller fixes, other fixes" }
    [PSCustomObject]@{ Date="20260602073902"; Notes="More Steam Controller stuff, other fixes" }
    [PSCustomObject]@{ Date="20260611123103"; Notes="NAT traversal bug fix" }
    [PSCustomObject]@{ Date="20260630145938"; Notes="Maylay language, fixes" }
)

if (-not $ATS) {
    Write-Host "No ATS parameter provided. Please select a version..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available versions:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $SteamVersions.Count; $i++) {
        Write-Host ("[{0:D2}] {1} - {2}" -f ($i+1), $SteamVersions[$i].Date, $SteamVersions[$i].Notes)
    }
    Write-Host ""
    $userInput = Read-Host "Enter the number of the version you want (1-$($SteamVersions.Count)), or paste a full timestamp"
    if ($userInput -match '^\d{1,2}$') {
        $index = [int]$userInput - 1
        if ($index -ge 0 -and $index -lt $SteamVersions.Count) {
            $ATS = $SteamVersions[$index].Date
        }
    } elseif ($userInput -match '^\d{14}$') {
        $ATS = $userInput
    }
    
    if (-not $ATS) {
        Write-Host "Invalid selection. Exiting..." -ForegroundColor Red
        exit
    }
}

Write-Host "Selected Archive Timestamp: $ATS" -ForegroundColor Green

Write-Host "Starting Steam Downgrade Script..." -ForegroundColor Cyan

# 1. Find Steam Installation Directory via Registry
$steamPath = $null
$registryPaths = @(
    "HKCU:\Software\Valve\Steam",
    "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
    "HKLM:\SOFTWARE\Valve\Steam"
)

foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        $propName = if ($path -match "HKCU") { "SteamPath" } else { "InstallPath" }
        $steamPath = (Get-ItemProperty -Path $path -Name $propName -ErrorAction SilentlyContinue).$propName
        if ($steamPath) {
            $steamPath = $steamPath -replace '/', '\'
            break
        }
    }
}


# Verify the path and steam.exe actually exist, and prompt if not found
while (-not $steamPath -or -not (Test-Path (Join-Path $steamPath "steam.exe"))) {
    if ($steamPath) {
        Write-Host "ERROR: Could not find steam.exe in '$steamPath'." -ForegroundColor Red
    } else {
        Write-Host "WARNING: Could not automatically detect Steam installation path." -ForegroundColor Yellow
    }
    
    $userInput = Read-Host "Please enter the full path to your Steam installation directory (e.g. C:\Program Files (x86)\Steam), or press Enter to exit"
    
    if (-not $userInput) {
        Write-Host "Exiting script..." -ForegroundColor Yellow
        exit
    }
    
    $steamPath = $userInput -replace '"', '' # Remove quotes if user dragged and dropped a folder
}

Write-Host "Found Steam Installation at: $steamPath" -ForegroundColor Green

# 2. Ensure Steam is completely closed
Write-Host "Closing Steam gracefully..."
$steamExe = Join-Path $steamPath "steam.exe"

if (Get-Process -Name "steam" -ErrorAction SilentlyContinue) {
    Start-Process -FilePath $steamExe -ArgumentList "-shutdown"
    
    # Wait up to 30 seconds for Steam to close
    $timeout = 30
    while ((Get-Process -Name "steam" -ErrorAction SilentlyContinue) -and $timeout -gt 0) {
        Start-Sleep -Seconds 1
        $timeout--
    }

    if (Get-Process -Name "steam" -ErrorAction SilentlyContinue) {
        Write-Host "Steam is taking too long to close, forcing shutdown..." -ForegroundColor Yellow
        Stop-Process -Name "steam" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "steamwebhelper" -Force -ErrorAction SilentlyContinue
    }
} else {
    # Even if "steam" process isn't found, stop any orphaned webhelpers
    Stop-Process -Name "steamwebhelper" -Force -ErrorAction SilentlyContinue
}

# 3. Create steam.cfg to block future auto-updates
$cfgPath = Join-Path $steamPath "steam.cfg"
$cfgLine = "BootStrapperInhibitAll=enable"

Write-Host "Applying update block ($cfgLine) to $cfgPath..."
try {
    if (Test-Path $cfgPath) {
        $content = Get-Content -Path $cfgPath -ErrorAction Stop
        if ($content -notcontains $cfgLine) {
            Add-Content -Path $cfgPath -Value $cfgLine -ErrorAction Stop
            Write-Host "steam.cfg updated successfully." -ForegroundColor Green
        } else {
            Write-Host "steam.cfg already contains the block rule." -ForegroundColor Green
        }
    } else {
        Set-Content -Path $cfgPath -Value $cfgLine -Force -ErrorAction Stop
        Write-Host "steam.cfg created successfully." -ForegroundColor Green
    }
} catch {
    Write-Host "WARNING: Could not update steam.cfg. You may need to run this script as Administrator." -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Red
}

# 4. Execute the Downgrade Command
$steamExe = Join-Path $steamPath "steam.exe"
$arguments = "-forcesteamupdate -forcepackagedownload -overridepackageurl http://web.archive.org/web/${ATS}if_/media.steampowered.com/client -exitsteam"

Write-Host "Starting downgrade download from the Wayback Machine..." -ForegroundColor Cyan
Write-Host "The Steam updater window will appear. It will automatically close when finished." -ForegroundColor Yellow

# Start Steam with the arguments and wait for it to exit
Start-Process -FilePath $steamExe -ArgumentList $arguments -Wait

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Green
Write-Host "Downgrade process complete! You can now launch Steam normally." -ForegroundColor Green
Write-Host "Note: Do not delete steam.cfg if you want to stay on this older version." -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Green

Pause