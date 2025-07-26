function y {
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
