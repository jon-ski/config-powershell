function Invoke-Robocopy {
    param (
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [switch]$Mirror,
        [switch]$ExcludeGit,
        [switch]$DryRun,
        [string]$Log
    )

    if (-not (Test-Path -Path $Source)) {
        gum log -s -t datetime -l error "Source does not exist" source $Source
        # Write-Host "[ERROR] Source does not exist: $Source" -ForegroundColor Red
        return
    }

    if (-not (Test-Path -Path $Destination)) {
        # Write-Host "[WARNING] Destination does not exist: $Destination" -ForegroundColor Yellow
        # $create = Read-Host "Do you want to create it? (y/n)"
        # if ($create -ne 'y') {
        #     Write-Host "[ABORTED] Destination creation declined." -ForegroundColor Red
        #     return
        # }
        gum log -s -t datetime -l warn "Destination does not exist" destination $Destination
        cmd.exe /c "gum confirm `"Create destination directory?`""
        if ($LASTEXITCODE -ne 0) {
            gum log -s -t datetime -l info "Destination creation declined"
            return
        }

        try {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
            # Write-Host "[OK] Created destination directory: $Destination" -ForegroundColor Green
            gum log -s -t datetime -l info "Destination created" destination $Destination
        } catch {
            # Write-Host "[ERROR] Failed to create destination: $_" -ForegroundColor Red
            gum log -s -t datetime -l error "Failed to create destination" error $_
            return
        }
    }

    $cmd = "robocopy `"$Source`" `"$Destination`" /R:2 /W:5"

    if ($Mirror) {
        # $confirm = Read-Host "This will mirror (including remove) files in the destination. Are you sure? (y/n)"
        # if ($confirm -ne 'y') {
        #     Write-Host "[ABORTED] Confirmation declined." -ForegroundColor Red
        #     return
        # }
        cmd.exe /c "gum confirm `"Mirror mode will DELETE files in destination. Continue?`""
        if ($LASTEXITCODE -ne 0) {
            gum log -s -t datetime -l info "Mirror confirmation declined"
            return
        }
        $cmd += " /MIR"
    }
    if ($ExcludeGit) { $cmd += " /XD .git" }
    if ($DryRun) { $cmd += " /L" }
    if ($Log) { $cmd += " /LOG+:`"$Log`"" }

    # Write-Host "[RUNNING] $cmd" -ForegroundColor Cyan
    gum log -s -t datetime -l info "Running" cmd $cmd
    cmd.exe /c $cmd
}

function rbpush {
    param (
        [Parameter(Mandatory = $true)][string]$Destination,
        [switch]$ExcludeGit,
        [switch]$DryRun,
        [string]$Log
    )

    $Source = (Get-Location).Path
    Invoke-Robocopy -Source $Source -Destination $Destination -Mirror -ExcludeGit:$ExcludeGit -DryRun:$DryRun -Log:$Log
}

function rbpull {
    param (
        [Parameter(Mandatory = $true)][string]$Source,
        [switch]$ExcludeGit,
        [switch]$DryRun,
        [string]$Log
    )

    $Destination = (Get-Location).Path
    Invoke-Robocopy -Source $Source -Destination $Destination -Mirror -ExcludeGit:$ExcludeGit -DryRun:$DryRun -Log:$Log
}

function rbcp {
    param (
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [switch]$ExcludeGit,
        [switch]$DryRun,
        [string]$Log
    )

    Invoke-Robocopy -Source $Source -Destination $Destination -ExcludeGit:$ExcludeGit -DryRun:$DryRun -Log:$Log
}
