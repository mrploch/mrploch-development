$loc = Get-Location
# Ensure posh-git module is installed or updated
if (-not (Get-Module -ListAvailable -Name posh-git))
{
    Write-Host "posh-git module not found. Installing..."
    Install-Module posh-git -Scope CurrentUser -Force
}
else
{
    Write-Host "posh-git module is already installed. Updating..."
    Update-Module posh-git -Force
}

# Ensure git-posh module is installed (for repo operations)
if (-not (Get-Module -ListAvailable -Name git-posh))
{
    Write-Host "git-posh module not found. Installing..."
    Install-Module git-posh -Scope CurrentUser -Force
}
else
{
    Write-Host "git-posh module is already installed."
}

# Get current script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
# Go up one directory
$parentDir = Split-Path $scriptDir -Parent
$devFolder = Join-Path $parentDir 'ploch-development'

if (-not (Test-Path $devFolder -PathType Container))
{
    Write-Host "'ploch-development' folder not found. Cloning repository..."
    Set-Location $parentDir
    if (-not (Get-Command git -ErrorAction SilentlyContinue))
    {
        Write-Error "Git is not installed or not in PATH."
        exit 1
    }
    Import-Module git-posh -ErrorAction SilentlyContinue
    git clone https://github.com/mrploch/mrploch-development.git ploch-development
}
else
{
    Write-Host "'ploch-development' folder exists. Pulling latest changes..."
    Set-Location $devFolder
    if (-not (Get-Command git -ErrorAction SilentlyContinue))
    {
        Write-Error "Git is not installed or not in PATH."
        exit 1
    }
    Import-Module git-posh -ErrorAction SilentlyContinue
    git pull
}
Set-Location $loc
