Push-Location $PSScriptRoot
dotnet ef database drop --force
./recreate-migrations.ps1
./update-database.ps1
Pop-Location
