$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    # 'database drop' is best-effort: on a fresh environment the database may not exist yet,
    # so a failure here must not halt the recreate/update that follows.
    try { dotnet ef database drop --force } catch { Write-Host "database drop skipped: $_" }
    ./recreate-migrations.ps1
    ./update-database.ps1
}
finally {
    Pop-Location
}
