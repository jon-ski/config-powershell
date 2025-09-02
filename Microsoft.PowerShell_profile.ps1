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

# Zoxide Setup
try {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
} catch {
    Write-Error "Failed to initialize zoxide, is it installed?"
}

