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

function Invoke-Robocopy {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [switch]$Mirror,
        [switch]$ExcludeGit,
        [switch]$DryRun,
        [string]$Log
    )

    if (-not (Test-Path -Path $Source)) {
        Write-Host "[ERROR] Source does not exist: $Source" -ForegroundColor Red
        return
    }

    if (-not (Test-Path -Path $Destination)) {
        Write-Host "[WARNING] Destination does not exist: $Destination" -ForegroundColor Yellow
        $create = Read-Host "Do you want to create it? (y/n)"
        if ($create -ne 'y') {
            Write-Host "[ABORTED] Destination creation declined." -ForegroundColor Red
            return
        }

        try {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
            Write-Host "[OK] Created destination directory: $Destination" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to create destination: $_" -ForegroundColor Red
            return
        }
    }

    $cmd = "robocopy `"$Source`" `"$Destination`" /R:2 /W:5"

    if ($Mirror) {
        $confirm = Read-Host "This will mirror (including remove) files in the destination. Are you sure? (y/n)"
        if ($confirm -ne 'y') {
            Write-Host "[ABORTED] Confirmation declined." -ForegroundColor Red
            return
        }
        $cmd += " /MIR"
    }
    if ($ExcludeGit) { $cmd += " /XD .git" }
    if ($DryRun) { $cmd += " /L" }
    if ($Log) { $cmd += " /LOG+:`"$Log`"" }

    Write-Host "[RUNNING] $cmd" -ForegroundColor Cyan
    cmd.exe /c $cmd
}

function rbpush {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [switch]$ExcludeGit,
        [switch]$DryRun,
        [string]$Log
    )

    $Source = (Get-Location).Path

    Invoke-Robocopy -Source $Source -Destination $Destination -Mirror -ExcludeGit:$ExcludeGit -DryRun:$DryRun -Log:$Log
}

function rbpull {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [switch]$ExcludeGit,
        [switch]$DryRun,
        [string]$Log
    )

    $Destination = (Get-Location).Path

    Invoke-Robocopy -Source $Source -Destination $Destination -Mirror -ExcludeGit:$ExcludeGit -DryRun:$DryRun -Log:$Log
}

function rbcp {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [switch]$ExcludeGit,
        [switch]$DryRun,
        [string]$Log
    )

    Invoke-Robocopy -Source $Source -Destination $Destination -ExcludeGit:$ExcludeGit -DryRun:$DryRun -Log:$Log
}


# ==============================================================================
# Help/Summary
# ==============================================================================

function profile-help {
    Write-Host "Available custom commands:" -ForegroundColor Cyan
    'y, rbpush, rbpull, rbcp' | ForEach-Object { " - $_" }
}
