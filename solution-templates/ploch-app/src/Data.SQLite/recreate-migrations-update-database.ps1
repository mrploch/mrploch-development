Push-Location $PSScriptRoot
Remove-Item *.db -Force -Confirm:$false -ErrorAction SilentlyContinue
./recreate-migrations.ps1
./update-database.ps1
Pop-Location
