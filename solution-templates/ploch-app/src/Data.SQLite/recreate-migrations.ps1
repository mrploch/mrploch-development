$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    Remove-Item Migrations -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
    dotnet ef migrations add Initial
    if ($LASTEXITCODE -ne 0) { throw "dotnet ef migrations add failed (exit code $LASTEXITCODE)" }
}
finally {
    Pop-Location
}
