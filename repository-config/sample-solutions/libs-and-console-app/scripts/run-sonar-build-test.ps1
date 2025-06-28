.\Clean-Repository.ps1
dotnet restore Ploch.Xopero.DevTask.sln
# $env:SONAR_TOKEN
dotnet sonarscanner begin /k:"mrploch_ploch-tinytools" /o:"mrploch" /d:sonar.login="$env:DEVTASK_SONAR_TOKEN" /d:sonar.cs.opencover.reportsPaths=**/CoverageResults/coverage.opencover.xml /d:sonar.host.url="https://sonarcloud.io"
dotnet build Ploch.Xopero.DevTask.sln --no-incremental --no-restore
dotnet test Ploch.Xopero.DevTask.sln --verbosity normal --no-build --logger "trx;LogFileName=TestOutputResults.xml" /p:CollectCoverage=true /p:CoverletOutput=./CoverageResults/ "/p:CoverletOutputFormat=cobertura%2copencover"
dotnet sonarscanner end /d:sonar.login="$env:DEVTASK_SONAR_TOKEN"

