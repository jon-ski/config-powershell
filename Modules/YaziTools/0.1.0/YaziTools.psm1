# Set YAZI_CONFIG_HOME using $HOME (cross-platform); create if missing
if (-not $env:YAZI_CONFIG_HOME) {
    $env:YAZI_CONFIG_HOME = Join-Path $HOME ".config\yazi"
}
if (-not (Test-Path -LiteralPath $env:YAZI_CONFIG_HOME)) {
    New-Item -ItemType Directory -Path $env:YAZI_CONFIG_HOME -Force | Out-Null
}

# (Optional) expose path for module scripts if desired
$script:YaziConfigHome = $env:YAZI_CONFIG_HOME

$public  = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public')  -Filter *.ps1 -ErrorAction Ignore
$private = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter *.ps1 -ErrorAction Ignore

foreach ($s in @($private + $public)) { . $s.FullName }

# export only public function names
Export-ModuleMember -Function $public.BaseName
