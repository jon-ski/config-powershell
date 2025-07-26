function y {
    $configFile = "$HOME\.config\yazi\file_path.txt"

    # Ensure config dir exists
    if (-not (Test-Path -Path (Split-Path $configFile))) {
        New-Item -ItemType Directory -Path (Split-Path $configFile) -Force | Out-Null
    }

    # Load saved path if available
    if (Test-Path $configFile) {
        $savedPath = Get-Content -Path $configFile -Encoding UTF8
    }

    # Check if YAZI_FILE_ONE is valid
    $needsUpdate = $false
    if (-not $env:YAZI_FILE_ONE -or -not (Test-Path $env:YAZI_FILE_ONE)) {
        $needsUpdate = $true
    } elseif ($savedPath -and ($env:YAZI_FILE_ONE -ne $savedPath)) {
        $needsUpdate = $true
    }

    # Prompt if needed
    if ($needsUpdate) {
        Write-Host "Set path for YAZI_FILE_ONE (e.g. full path to file.exe):"
        $userInput = Read-Host "Path"

        if (-not (Test-Path $userInput)) {
            Write-Error "File does not exist: $userInput"
            return
        }

        # Save to config file and set environment variable
        Set-Content -Path $configFile -Value $userInput -Encoding UTF8
        [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $userInput, "User")
    }

    $tmp = [System.IO.Path]::GetTempFileName()
    # yazi $args --cwd-file="$tmp"
    # $cwd = Get-Content -Path $tmp -Encoding UTF8
    # if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
    #     Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    # }
    # Remove-Item -Path $tmp

    yazi --cwd-file="$tmp" @args
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if ($cwd -and (Test-Path $cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp -Force
}

$env:YAZI_CONFIG_HOME = "$env:USERPROFILE\.config\yazi\"
