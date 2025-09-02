$env:EDITOR = "hx" # helix

function prompt {
    # Powerline glyphs
    $line_tr = "╮"
    $line_br = "╯"
    $line_tl = "╭"
    $line_br = "╰"
    $line_v = "│"
    $line_h = "─"
    $arrow_bottom_right = "󱞩"
    $L  = ''   # left rounded cap
    $R  = ''   # right rounded cap
    # $Jr = ''
    $Jr = ''
    $ico_clock = "󰥔"
    $ico_dir = ""
    $dir_sep = ""

    # Helpers
    function FG([string]$n) { $PSStyle.Foreground."$n" }
    function BG([string]$n) { $PSStyle.Background."$n" }
    function Seg([string]$text,[string]$bg,[string]$fg) { "$(BG $bg)$(FG $fg) $text $($PSStyle.Reset)" }
    function Join([string]$prevBg,[string]$nextBg) { "$(BG $prevBg)$(FG $nextBg)$Jr$($PSStyle.Reset)" }

    # Segment palette (map to your terminal theme)
    $NameBg="Green"; $NameFg="Black"
    $TimeBg="Blue";  $TimeFg="Black"
    $DirBg="Yellow"; $DirFg="Black"

    # Top left bracket thing
    # Write-Host ($line_tl + $line_h + " ") -NoNewline
    Write-Host ("`n ") -NoNewline

    # Write Host/Name
    Write-Host $L -ForegroundColor $NameBg -NoNewline
    Write-Host ("  " + (hostname) + " ") -BackgroundColor $NameBg -ForegroundColor $NameFg -NoNewline
    Write-Host $Jr -BackgroundColor $TimeBg -ForegroundColor $NameBg -NoNewline
    
    # Clock
    Write-Host (" " + $ico_clock + " ") -BackgroundColor $TimeBg -ForegroundColor $TimeFg -NoNewline
    Write-Host (Get-Date -Format 'HH:mm:ss') -BackgroundColor $TimeBg -ForegroundColor $TimeFg -NoNewline
    Write-Host " " -BackgroundColor $TimeBg -NoNewline
    Write-Host $Jr -BackgroundColor $DirBg -ForegroundColor $TimeBg -NoNewline
    Write-Host " " -BackgroundColor $DirBg -NoNewline

    # Directory/Path (compact if dir level > 4)
    $path = (Get-Location).Path
    if ($pwd.Provider.Name -ne 'FileSystem') {
        $compact = @($path)
    } else {
        $root  = [System.IO.Path]::GetPathRoot($path)
        $drive = $root.TrimEnd('\')
        $rest  = $path.Substring($root.Length)
        $parts = @($rest -split '[\\/]+' | Where-Object { $_ })
        switch ($parts.Count) {
            0 { $compact = @($drive), $dir_sep }
            1 { $compact = @($drive, $dir_sep, $parts[0]) }
            2 { $compact = @($drive, $dir_sep, $parts[0], $dir_sep, $parts[1]) }
            # 3 { $compact = @($drive,$dir_sep, $parts[0], $dir_sep, $parts[1], $dir_sep, $parts[2]) }
            default { $compact = @($drive,$dir_sep, '', $dir_sep, $parts[-2],$dir_sep, $parts[-1]) }
        }
    }
    Write-Host ($ico_dir + " " + $compact + " ") -BackgroundColor $DirBg -ForegroundColor $DirFg -NoNewline
    Write-Host $R -ForegroundColor $DirBg -NoNewline

    # Second-Line
    # Write-Host ("`n" + $line_br + $line_h + "─") -NoNewline
    Write-Host ("`n") -NoNewline
    

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
