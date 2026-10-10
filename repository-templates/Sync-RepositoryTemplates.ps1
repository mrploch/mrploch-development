#Requires -Version 7.2
<#
.SYNOPSIS
    Copies the canonical shared files into the mrploch .NET GitHub template repositories.

.DESCRIPTION
    repository-templates/shared/ holds the files that are identical in every template repository: the CI workflows,
    the bootstrap script, analyser and editor settings, and the hygiene files. This script copies them into local
    clones of the template repositories listed in templates.json, which must sit side by side under -TemplatesRoot
    (by default the parent of this repository, the mrploch workspace root).

    In shared files, __REPOSITORY__ is replaced with the target repository's name. Files a template lists under
    "exclude" in templates.json are template-specific there and are left alone.

    The script changes only the working trees. Review, commit and open a pull request in each template repository
    as usual; the template's own CI (including the Template Bootstrap workflow) then verifies the result.

.PARAMETER TemplatesRoot
    The folder containing the template repository clones. Defaults to the parent of this repository.

.PARAMETER Template
    Limits the run to the named templates (the "name" values in templates.json). Defaults to all.

.PARAMETER Check
    Changes nothing; reports every file that differs from the canonical copy and exits with code 1 if any does.
    Use it to detect drift, for example after a template repository was edited directly.

.EXAMPLE
    ./repository-templates/Sync-RepositoryTemplates.ps1 -WhatIf

    Lists the files that would be updated in every template repository.

.EXAMPLE
    ./repository-templates/Sync-RepositoryTemplates.ps1 -Template console -Check

    Reports whether the console template has drifted from the canonical shared files.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $TemplatesRoot = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '..'),

    [string[]] $Template,

    [switch] $Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedRoot = Join-Path $PSScriptRoot 'shared'
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'templates.json') -Raw | ConvertFrom-Json
$templates = @($manifest.templates | Where-Object { -not $Template -or $_.name -in $Template })
if ($Template -and $templates.Count -ne $Template.Count) {
    $known = ($manifest.templates.name) -join ', '
    throw "[Sync-RepositoryTemplates] Unknown template in '$($Template -join ', ')'. Known templates: $known."
}

$sharedFiles = Get-ChildItem -LiteralPath $sharedRoot -Recurse -File -Force |
    ForEach-Object { [System.IO.Path]::GetRelativePath($sharedRoot, $_.FullName).Replace('\', '/') } |
    Sort-Object

# The canonical bytes for one template: the shared file as is, or with __REPOSITORY__ replaced by the template's
# repository name. A byte-order mark is kept exactly when the canonical file has one.
function Get-ExpectedContent([byte[]] $Source, [string] $Repository) {
    $hasBom = $Source.Length -ge 3 -and $Source[0] -eq 0xEF -and $Source[1] -eq 0xBB -and $Source[2] -eq 0xBF
    $offset = if ($hasBom) { 3 } else { 0 }
    $text = [System.Text.Encoding]::UTF8.GetString($Source, $offset, $Source.Length - $offset)
    if (-not $text.Contains('__REPOSITORY__')) {
        return , $Source
    }

    $body = [System.Text.Encoding]::UTF8.GetBytes($text.Replace('__REPOSITORY__', $Repository))
    if ($hasBom) {
        return , ([byte[]](0xEF, 0xBB, 0xBF) + $body)
    }

    return , $body
}

$drift = 0
foreach ($entry in $templates) {
    $repositoryPath = Join-Path $TemplatesRoot $entry.repository
    if (-not (Test-Path -LiteralPath (Join-Path $repositoryPath '.git'))) {
        throw "[Sync-RepositoryTemplates] '$repositoryPath' is not a clone of $($entry.repository). Clone it beside this repository or pass -TemplatesRoot."
    }

    $changed = 0
    foreach ($file in $sharedFiles | Where-Object { $_ -notin $entry.exclude }) {
        $expectedBytes = Get-ExpectedContent ([System.IO.File]::ReadAllBytes((Join-Path $sharedRoot $file))) $entry.repository

        $targetPath = Join-Path $repositoryPath $file
        $actualBytes = if (Test-Path -LiteralPath $targetPath) { [System.IO.File]::ReadAllBytes($targetPath) } else { $null }
        if ($null -ne $actualBytes -and [System.Linq.Enumerable]::SequenceEqual([byte[]]$actualBytes, [byte[]]$expectedBytes)) {
            continue
        }

        $changed++
        $state = if ($null -eq $actualBytes) { 'missing' } else { 'differs' }
        if ($Check) {
            Write-Output "[Sync-RepositoryTemplates] $($entry.repository): $file $state"
            continue
        }

        if ($PSCmdlet.ShouldProcess("$($entry.repository)/$file", "Update ($state)")) {
            New-Item -ItemType Directory -Force -Path (Split-Path $targetPath -Parent) | Out-Null
            [System.IO.File]::WriteAllBytes($targetPath, [byte[]]$expectedBytes)
            Write-Output "[Sync-RepositoryTemplates] $($entry.repository): updated $file ($state)"
        }
    }

    if ($changed -eq 0) {
        Write-Output "[Sync-RepositoryTemplates] $($entry.repository): up to date"
    }
    $drift += $changed
}

if ($Check -and $drift -gt 0) {
    Write-Output "[Sync-RepositoryTemplates] $drift file(s) differ from repository-templates/shared. Run without -Check to update them."
    exit 1
}
