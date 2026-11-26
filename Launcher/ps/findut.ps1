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
$c += @('C:\Steam\steamapps\common\Unreal Tournament',
        'C:\Program Files (x86)\Steam\steamapps\common\Unreal Tournament',
        'C:\Program Files\Steam\steamapps\common\Unreal Tournament',
        'D:\Steam\steamapps\common\Unreal Tournament',
        'D:\SteamLibrary\steamapps\common\Unreal Tournament',
        'E:\SteamLibrary\steamapps\common\Unreal Tournament',
        'C:\GOG Games\Unreal Tournament GOTY',
        'C:\UnrealTournament')
foreach ($d in $c) {
    if ($d -and (Test-Path -LiteralPath (Join-Path $d 'System\Botpack.u')) -and (Test-Path -LiteralPath (Join-Path $d 'Maps\CTF-Face.unr'))) {
        Write-Output $d
        break
    }
}
