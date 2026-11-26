# One time: Auto Taunt on by default.
$f = Join-Path $env:UTM_GAME 'System\User.ini'
$t = @(Get-Content -LiteralPath $f) -replace '^bAutoTaunt=False$', 'bAutoTaunt=True'
Set-Content -LiteralPath $f -Value $t -Encoding Default
