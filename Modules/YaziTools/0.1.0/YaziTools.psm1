# <profileDir>\modules\YaziTools\0.1.0\YaziTools.psm1
$public  = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public')  -Filter *.ps1 -ErrorAction Ignore
$private = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter *.ps1 -ErrorAction Ignore

foreach ($s in @($private + $public)) { . $s.FullName }

# export only public function names
Export-ModuleMember -Function $public.BaseName
