Push-Location $PSScriptRoot
Remove-Item Migrations -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
dotnet ef migrations add Initial
Pop-Location
