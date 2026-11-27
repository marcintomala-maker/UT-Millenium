# One time: a Desktop shortcut "UT Millenium" with the Unreal Tournament icon
# (a .cmd file can't have its own icon, a shortcut can).
try {
    $desk = [Environment]::GetFolderPath('Desktop')
    $lnk = Join-Path $desk 'UT Millenium.lnk'
    $sh = New-Object -ComObject WScript.Shell
    $s = $sh.CreateShortcut($lnk)
    $s.TargetPath = $env:UTM_SELF
    $s.WorkingDirectory = Split-Path -Parent $env:UTM_SELF
    $s.IconLocation = (Join-Path $env:UTM_GAME 'System\UnrealTournament.exe') + ',0'
    $s.Description = 'UT Millenium - Quick Play for Unreal Tournament'
    $s.Save()
    Set-Content -LiteralPath (Join-Path $env:UTM_GAME 'shortcut.done') -Value $lnk
    Write-Output ('shortcut ' + $lnk)
} catch {
    Write-Output ('no shortcut: ' + $_)
}
