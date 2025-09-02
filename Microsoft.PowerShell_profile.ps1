$env:EDITOR = "hx" # helix

if (-not $script:Prompt_HostName) {
    $script:Prompt_Hostname = [System.Environment]::MachineName
}

function prompt {
    <#
    .SYNOPSIS
        Two-line Powerline-style prompt with host, time, and compact path.
    .NOTES
        Returns a single space so the caret sits after the second-line arrow.
    #>

    # ── Glyphs
    $L   = ''     # left rounded cap
    $R   = ''     # right rounded cap
    $Jr  = ''     # join (rounded)
    $IconClock = '󰥔'
    $IconDir   = ''
    $Sep       = ''  # path separator + second-line prompt marker

    # ── Predefined Strings
    $hostname = $script:Prompt_Hostname
    $timeStr = [DateTime]::UtcNow.ToString("HH:mm:ss") # local time

    # ── Palette (map to your terminal theme)
    $NameBg="Green";  $NameFg="Black"
    $TimeBg="Blue";   $TimeFg="Black"
    $PathBg="Yellow"; $PathFg="Black"

    # ── Style helpers (use PS 7+ $PSStyle)
    function FG([string]$n) { $PSStyle.Foreground."$n" }
    function BG([string]$n) { $PSStyle.Background."$n" }
    function Seg([string]$text,[string]$bg,[string]$fg) { "$(BG $bg)$(FG $fg)$text$($PSStyle.Reset)" }
    function Join([string]$fromBg,[string]$toBg)        { "$(BG $toBg)$(FG $fromBg)$Jr$($PSStyle.Reset)" }
    function CapL([string]$bg)                          { "$(FG $bg)$L$($PSStyle.Reset)" }
    function CapR([string]$bg)                          { "$(FG $bg)$R$($PSStyle.Reset)" }

    # ── Compact path formatter
    function Format-Path {
        if ($pwd.Provider.Name -ne 'FileSystem') { return $pwd.Path }

        $full  = $pwd.Path
        $root  = [System.IO.Path]::GetPathRoot($full)
        $drive = $root.TrimEnd('\','/')
        $rest  = if ($root.Length -lt $full.Length) { $full.Substring($root.Length) } else { '' }
        $parts = $rest.Split(@('\','/'), [StringSplitOptions]::RemoveEmptyEntries)

        switch ($parts.Count) {
            0 { return "$drive" }
            1 { return "$drive $Sep $($parts[0])" }
            2 { return "$drive $Sep $($parts[0]) $Sep $($parts[1])" }
            default { return "$drive $Sep  $Sep $($parts[-2]) $Sep $($parts[-1])" }
        }
    }

    # ── Line 1: host • time • path
    $line1 =
        "`n " +
        (CapL  $NameBg) +
        (Seg   "  $($hostname) "            $NameBg $NameFg) +
        (Join  $NameBg $TimeBg) +
        (Seg   " $IconClock $([DateTime]::Now.ToString('HH:mm:ss')) " $TimeBg $TimeFg) +
        (Join  $TimeBg $PathBg) +
        (Seg   " $IconDir $(Format-Path) "  $PathBg $PathFg) +
        (CapR  $PathBg)

    # ── Line 2: prompt marker
    $line2 = "`n$Sep"

    # ── Emit
    Write-Host $line1 -NoNewline
    Write-Host $line2 -NoNewline
    return ' '
}

$env:YAZI_CONFIG_HOME = "$env:USERPROFILE\.config\yazi\"

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

function head {
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}

function tail {
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}

function htmlcopy {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string] $InputObject
    )

    begin {
        $sb = [System.Text.StringBuilder]::new()
    }

    process {
        $null = $sb.AppendLine($InputObject)
    }

    end {
        $data = $sb.ToString().TrimEnd()

        if (-not $data) {
            Write-Error "No input received"
            return
        }

        Add-Type -AssemblyName System.Windows.Forms
        $clip = New-Object Windows.Forms.DataObject
        $clip.SetData("HTML Format", $data)
        [Windows.Forms.Clipboard]::SetDataObject($clip, $true)
    }
}

# Zoxide Setup
try {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
} catch {
    Write-Error "Failed to initialize zoxide, is it installed?"
}

# ==============================================================================
# Help/Summary
# ==============================================================================

function profile-help {
    Write-Host "Available custom commands:" -ForegroundColor Cyan
    'y, rbpush, rbpull, rbcp' | ForEach-Object { " - $_" }
}
