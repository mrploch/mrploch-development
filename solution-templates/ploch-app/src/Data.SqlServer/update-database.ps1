$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    dotnet ef database update
    if ($LASTEXITCODE -ne 0) { throw "dotnet ef database update failed (exit code $LASTEXITCODE)" }
}
finally {
    Pop-Location
}
