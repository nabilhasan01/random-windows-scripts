$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$scriptUrl = 

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
        Write-Host "Successfully added $destDir to the System PATH." -ForegroundColor Green
    } else {
        Write-Host "$destDir is already in the PATH." -ForegroundColor Yellow
    }

}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
}