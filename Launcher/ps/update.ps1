# Runs on every start: window sizes, search paths, console class.
$ErrorActionPreference = 'Stop'
$ut  = $env:UTM_UT
$sys = Join-Path $env:UTM_GAME 'System'

$dw = 1920; $dh = 1080
try {
    $v = @(Get-CimInstance Win32_VideoController | Where-Object { $_.CurrentVerticalResolution -gt 0 })
    if ($v.Count -gt 0) { $dw = [int]$v[0].CurrentHorizontalResolution; $dh = [int]$v[0].CurrentVerticalResolution }
} catch { }
$ph = [int]($dh * 0.82); $ph = $ph - ($ph % 16); $pw = [int]($ph * 9 / 16)

function Set-IniKeys($lines, [string]$section, $keys) {
    $out = @(); $in = $false; $found = $false; $done = @{}
    foreach ($l in $lines) {
        if ($l -match '^\[(.+)\]$') {
            if ($in) { foreach ($k in $keys.Keys) { if (-not $done.ContainsKey($k)) { $out += ($k + '=' + $keys[$k]); $done[$k] = 1 } } }
            $in = ($Matches[1] -eq $section)
            if ($in) { $found = $true }
            $out += $l
            continue
        }
        if ($in -and ($l -match '^([^=]+)=')) {
            $k = $Matches[1]
            if ($keys.ContainsKey($k)) {
                if (-not $done.ContainsKey($k)) { $out += ($k + '=' + $keys[$k]); $done[$k] = 1 }
                continue
            }
        }
        $out += $l
    }
    if ($in) { foreach ($k in $keys.Keys) { if (-not $done.ContainsKey($k)) { $out += ($k + '=' + $keys[$k]); $done[$k] = 1 } } }
    if (-not $found) {
        $out += ''
        $out += ('[' + $section + ']')
        foreach ($k in $keys.Keys) { $out += ($k + '=' + $keys[$k]) }
    }
    return ,$out
}

# UnrealTournament.ini
$f = Join-Path $sys 'UnrealTournament.ini'
$paths = @('../System/*.u', '../Textures/*.utx', '../Maps/*.unr', '../Sounds/*.uax', '../Music/*.umx',
           ($ut + '\Maps\*.unr'), ($ut + '\Textures\*.utx'), ($ut + '\Sounds\*.uax'), ($ut + '\Music\*.umx'))
$out = @(); $sec = ''
foreach ($l in (Get-Content -LiteralPath $f)) {
    if ($l -match '^\[(.+)\]$') { $sec = $Matches[1] }
    if ($sec -eq 'Core.System' -and ($l -match '^Paths=')) { continue }
    $out += $l
    if ($l -eq '[Core.System]') { foreach ($p in $paths) { $out += ('Paths=' + $p) } }
}
$out = Set-IniKeys $out 'URL' @{ LocalMap = 'UT-Logo-Map.unr' }
$out = Set-IniKeys $out 'FirstRun' @{ FirstRun = '469' }
$out = Set-IniKeys $out 'Engine.Engine' @{ Console = 'UTMillenium.UTMConsole'; CdPath = '' }
$out = Set-IniKeys $out 'WinDrv.WindowsClient' @{ StartupFullscreen = 'False'; StartupBorderless = 'False'; UseJoystick = 'False';
        WindowedViewportX = $pw; WindowedViewportY = $ph; FullscreenViewportX = $dw; FullscreenViewportY = $dh }
Set-Content -LiteralPath $f -Value $out -Encoding Default

# UTMillenium.ini
$g = Join-Path $sys 'UTMillenium.ini'
$m = @()
if (Test-Path -LiteralPath $g) { $m = @(Get-Content -LiteralPath $g) }
$m = Set-IniKeys $m 'UTMillenium.UTMSettings' @{ PortraitX = $pw; PortraitY = $ph; DesktopX = $dw; DesktopY = $dh; bAddMapsRequest = 'False' }
Set-Content -LiteralPath $g -Value $m -Encoding Default

Write-Output ('screen ' + $dw + 'x' + $dh + ', menu window ' + $pw + 'x' + $ph)
