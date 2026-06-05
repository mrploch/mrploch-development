$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    # Remove the SQLite database together with its write-ahead-log and shared-memory sidecar files.
    Remove-Item *.db, *.db-wal, *.db-shm -Force -Confirm:$false -ErrorAction SilentlyContinue
    ./recreate-migrations.ps1
    ./update-database.ps1
}
finally {
    Pop-Location
}
