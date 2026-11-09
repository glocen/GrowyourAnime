# Serves a Rojo project and restarts it if it crashes.
# Rojo 7.7.1 crashes ("change_processor.rs ... cannot find the file specified") when files vanish for a moment,
# for example during a git pull or rebase. After a restart, reconnect each Studio: Plugins -> Rojo -> Connect.
# Run from the repo root:  .\tools\rojo-serve.ps1   (Ctrl+C twice to stop)
# A second project on its own port:  .\tools\rojo-serve.ps1 other.project.json
param([string]$Project = "default.project.json")

$rojo = Join-Path $env:USERPROFILE ".rokit\bin\rojo.exe"
Set-Location (Split-Path $PSScriptRoot -Parent)
while ($true) {
    & $rojo serve $Project
    Write-Host "[rojo-serve] Rojo stopped at $(Get-Date -Format HH:mm:ss); restarting in 2 s. Reconnect Studio afterwards." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}
