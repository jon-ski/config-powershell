function y {
    [CmdletBinding()]
    param()

    $configFile = Join-Path $HOME '.config\yazi\file_path.txt'
    $configDir  = Split-Path $configFile -Parent

    if (-not (Test-Path -LiteralPath $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    if (Test-Path -LiteralPath $configFile) {
        $savedPath = Get-Content -Path $configFile -Encoding UTF8 -ErrorAction SilentlyContinue
    }

    $needsUpdate = $false
    if (-not $env:YAZI_FILE_ONE -or -not (Test-Path -LiteralPath $env:YAZI_FILE_ONE)) {
        $needsUpdate = $true
    } elseif ($savedPath -and ($env:YAZI_FILE_ONE -ne $savedPath)) {
        $needsUpdate = $true
    }

    if ($needsUpdate) {
        Write-Host "Set path for YAZI_FILE_ONE (e.g., full path to file.exe):"
        $userInput = Read-Host "Path"

        if (-not (Test-Path -LiteralPath $userInput)) {
            Write-Error "File does not exist: $userInput"
            return
        }

        Set-Content -Path $configFile -Value $userInput -Encoding UTF8
        [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $userInput, "User")
        $env:YAZI_FILE_ONE = $userInput # current session
    }

    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        # forward any args passed to y -> yazi
        yazi --cwd-file="$tmp" @args
        $cwd = Get-Content -Path $tmp -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($cwd -and (Test-Path -LiteralPath $cwd) -and $cwd -ne $PWD.Path) {
            Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
        }
    }
    finally {
        if (Test-Path -LiteralPath $tmp) {
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        }
    }
}
