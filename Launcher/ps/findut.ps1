# Prints the first folder that looks like Unreal Tournament (Steam first).
$c = @()
$k = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 13240'
foreach ($r in @($k, 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 13240')) {
    $p = Get-ItemProperty -LiteralPath $r -ErrorAction SilentlyContinue
    if ($p -and $p.InstallLocation) { $c += $p.InstallLocation }
}
$s = Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue
if ($s -and $s.SteamPath) {
    $sp = $s.SteamPath -replace '/', '\'
    $c += (Join-Path $sp 'steamapps\common\Unreal Tournament')
    $vdf = Join-Path $sp 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        $q = [string][char]34
        foreach ($line in (Get-Content -LiteralPath $vdf)) {
            $t = $line.Trim()
            if ($t.StartsWith($q + 'path' + $q)) {
                $parts = $t.Split($q)
                if ($parts.Count -ge 4) {
                    $lib = $parts[3] -replace '\\\\', '\'
                    $c += (Join-Path $lib 'steamapps\common\Unreal Tournament')
                }
            }
        }
    }
}
# Common places on every drive (C, D, E, F, G, H).
$folders = @(
    'Steam\steamapps\common\Unreal Tournament',
    'SteamLibrary\steamapps\common\Unreal Tournament',
    'Steam Library\steamapps\common\Unreal Tournament',
    'Program Files (x86)\Steam\steamapps\common\Unreal Tournament',
    'Program Files\Steam\steamapps\common\Unreal Tournament',
    'Games\Steam\steamapps\common\Unreal Tournament',
    'Games\SteamLibrary\steamapps\common\Unreal Tournament',
    'GOG Games\Unreal Tournament GOTY',
    'GOG Games\Unreal Tournament',
    'GOG Galaxy\Games\Unreal Tournament GOTY',
    'Program Files (x86)\GOG Galaxy\Games\Unreal Tournament GOTY',
    'Program Files (x86)\GOG.com\Unreal Tournament GOTY',
    'Games\Unreal Tournament GOTY',
    'Games\Unreal Tournament',
    'Games\UnrealTournament',
    'Program Files (x86)\Unreal Tournament',
    'Program Files\Unreal Tournament',
    'Program Files (x86)\UnrealTournament',
    'Program Files\UnrealTournament',
    'Unreal Tournament',
    'UnrealTournament',
    'UT99',
    'UT')
foreach ($drv in @('C', 'D', 'E', 'F', 'G', 'H')) {
    if (Test-Path -LiteralPath ($drv + ':\')) {
        foreach ($f in $folders) { $c += ($drv + ':\' + $f) }
    }
}
foreach ($d in $c) {
    if ($d -and (Test-Path -LiteralPath (Join-Path $d 'System\Botpack.u')) -and (Test-Path -LiteralPath (Join-Path $d 'Maps\CTF-Face.unr'))) {
        Write-Output $d
        break
    }
}
