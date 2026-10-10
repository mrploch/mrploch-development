#Requires -Version 7.2
<#
.SYNOPSIS
    Turns a fresh copy of this template into a named repository.

.DESCRIPTION
    Replaces the template's placeholder names, read from scripts/template.json, in every tracked text file and in
    file and directory names:

        productToken     ->  the product part of -Name (for example "Orders" for "Ploch.Orders"). Where the token
                             is directly followed by an identifier character, as in "TemplateAppDbContext", the
                             product is used without its dots ("Text.Slugs" -> "TextSlugsDbContext"), so a
                             multi-segment name still produces valid C# identifiers.
        kebab-case form  ->  the product in kebab case, for command and file names: "template-app" becomes
                             "text-slugs" for "Ploch.Text.Slugs".
        repositoryToken  ->  -RepositoryName

    It also removes the template-only sections of README.md (between "<!-- template-only:start -->" and
    "<!-- template-only:end -->"), then deletes the template-only files: this script, scripts/template.json and
    the Template Bootstrap workflow that tests it.

    Run it once, from the repository root, straight after creating the repository with "Use this template".
    Template change-log entries are deleted too: they describe the template's history, not the new repository's.

    It refuses to run with uncommitted changes, so the result can be reviewed with `git status` and `git diff`,
    and undone with `git reset --hard HEAD` (renames are staged by `git mv`, so `git checkout .` is not enough).
    It is idempotent: a repository with no placeholders left is reported and left untouched.

.PARAMETER Name
    The product's root name, which becomes the solution, project, assembly, package and namespace prefix.
    It must start with "Ploch." and consist of PascalCase segments, for example "Ploch.Orders" or "Ploch.Text.Slugs".

.PARAMETER RepositoryName
    The GitHub repository name, used in URLs and badges. Defaults to the name of the 'origin' remote, or to
    the current directory name when there is no remote.

.PARAMETER KeepScript
    Keeps the template-only files (this script and its workflow) after a successful run.
    Intended for testing the script itself.

.EXAMPLE
    ./scripts/Initialize-Repository.ps1 -Name Ploch.Orders -WhatIf

    Lists every file the script would change or rename, without changing anything.

.EXAMPLE
    ./scripts/Initialize-Repository.ps1 -Name Ploch.Orders

    Initialises the repository as Ploch.Orders, taking the repository name from the 'origin' remote.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    # Case-sensitive: each segment must start with an upper-case letter, which also rules out C# keywords.
    [ValidatePattern('^Ploch(\.[A-Z][A-Za-z0-9]*)+$', Options = 'None')]
    [string] $Name,

    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string] $RepositoryName,

    [switch] $KeepScript
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TemplateOnlyPattern = '(?s)\r?\n?<!-- template-only:start -->.*?<!-- template-only:end -->\r?\n?'

$root = (git rev-parse --show-toplevel 2>$null)
if (-not $root) {
    throw '[Initialize-Repository] Run this script inside the git repository created from the template.'
}
Set-Location $root
$scriptPath = [System.IO.Path]::GetRelativePath($root, $PSCommandPath).Replace('\', '/')
$templateConfigPath = 'scripts/template.json'
$templateOnlyFiles = @($scriptPath, $templateConfigPath, '.github/workflows/template-bootstrap.yml')

if (-not (Test-Path -LiteralPath $templateConfigPath)) {
    Write-Information "[Initialize-Repository] $templateConfigPath is gone; the repository is already initialised." -InformationAction Continue
    return
}
$templateConfig = Get-Content -LiteralPath $templateConfigPath -Raw | ConvertFrom-Json
$ProductToken = $templateConfig.productToken
$RepositoryToken = $templateConfig.repositoryToken
if (-not $ProductToken -or -not $RepositoryToken) {
    throw "[Initialize-Repository] $templateConfigPath must define productToken and repositoryToken."
}

if (-not $RepositoryName) {
    $remote = git remote get-url origin 2>$null
    $RepositoryName = if ($remote) { ($remote -split '[/:]')[-1] -replace '\.git$', '' } else { Split-Path $root -Leaf }
    if ($RepositoryName -notmatch '^[A-Za-z0-9._-]+$') {
        throw "[Initialize-Repository] Cannot use '$RepositoryName' as the repository name; pass -RepositoryName explicitly."
    }
    Write-Information "[Initialize-Repository] Repository name: $RepositoryName" -InformationAction Continue
}

if ($Name -cmatch '(Tests|IntegrationTests|TestingSupport)$') {
    # Directory.Build.props treats projects whose names end in "Tests" as test projects, which are never packed.
    throw "[Initialize-Repository] '$Name' ends like a test project name; choose a product name such as 'Ploch.Orders'."
}

$product = $Name.Substring('Ploch.'.Length)
$reservedSegment = $product.Split('.') | Where-Object { $_ -match '^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])$' } | Select-Object -First 1
if ($reservedSegment) {
    # These names cannot be used for files or directories on Windows, and the projects are named after the product.
    throw "[Initialize-Repository] '$reservedSegment' is a reserved file name on Windows; choose another product name."
}
if ($product -ceq $ProductToken) {
    throw "[Initialize-Repository] '$Name' is the template's own placeholder name; choose the new product's name."
}
# "Text.Slugs" -> "TextSlugs": used where the token is part of a longer identifier, such as a DbContext class name.
$productIdentifier = $product.Replace('.', '')
# "TemplateApp" -> "template-app", "Text.Slugs" -> "text-slugs": the forms used for command names and file names.
function ConvertTo-KebabCase([string] $Value) {
    return ($Value -creplace '(?<=[a-z0-9])(?=[A-Z])', '-').Replace('.', '-').ToLowerInvariant()
}
$kebabToken = ConvertTo-KebabCase $ProductToken
$productKebab = ConvertTo-KebabCase $product

# Matches any form of a placeholder; used to find files and paths that still need converting.
$anyTokenPattern = '(' + ((@($RepositoryToken, $kebabToken, $ProductToken) | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')'

$tokenPattern = '(?<repository>' + [regex]::Escape($RepositoryToken) + ')|(?<kebab>' + [regex]::Escape($kebabToken) + ')|(?<product>' +
    [regex]::Escape($ProductToken) + ')(?<identifier>(?=[A-Za-z0-9_]))?'

# Replaces both placeholders in a single pass, so a new name that itself contains a placeholder (for example
# "Ploch.TemplateApp.Tools") is never processed a second time.
function Convert-TemplateToken([string] $Text) {
    return [regex]::Replace($Text, $tokenPattern, {
            param($match)
            if ($match.Groups['repository'].Success) { return $RepositoryName }
            if ($match.Groups['kebab'].Success) { return $productKebab }
            if ($match.Groups['identifier'].Success) { return $productIdentifier }
            return $product
        })
}

$trackedFiles = @(git ls-files) | Where-Object { $_ -notin $templateOnlyFiles }
$filesWithTokens = @($trackedFiles | Where-Object {
        $content = Get-Content -LiteralPath $_ -Raw -ErrorAction SilentlyContinue
        $_ -cmatch $anyTokenPattern -or ($content -and ($content.Contains($ProductToken) -or $content.Contains($RepositoryToken) -or $content.Contains($kebabToken)))
    })

if ($filesWithTokens.Count -eq 0) {
    Write-Information '[Initialize-Repository] No template placeholders remain; the repository is already initialised.' -InformationAction Continue
    return
}

if (-not $WhatIfPreference -and (git status --porcelain)) {
    throw '[Initialize-Repository] The working tree has uncommitted changes. Commit or stash them first, so the result can be reviewed and undone.'
}

# Renaming a namespace can change where its using directive sorts ("Ploch.TemplateApp" sorts after "Ploch.Data",
# "Ploch.Accounts" before it), which StyleCop then reports as SA1210. This re-sorts each file's leading block of
# using directives the way StyleCop expects: System namespaces first, then the others alphabetically, then
# "using static" directives, then aliases.
function Format-UsingDirective([string] $Text) {
    $lines = $Text -split '\r?\n'
    $first = -1
    $last = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^using [^(]+;\s*$') {
            if ($first -lt 0) { $first = $i }
            $last = $i
        }
        elseif ($first -ge 0 -and $lines[$i].Trim() -ne '') {
            break
        }
    }
    if ($first -lt 0) {
        return $Text
    }

    $directives = @($lines[$first..$last] | Where-Object { $_.Trim() -ne '' })
    $comparer = [System.StringComparer]::OrdinalIgnoreCase
    $namespaceOf = { param($line) ($line -replace '^using (static )?', '' -replace ';\s*$', '').Trim() }
    $plain = @($directives | Where-Object { $_ -notmatch '^using static ' -and $_ -notmatch '^using \w+\s*=' })
    $system = [System.Collections.Generic.List[string]]::new()
    $other = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $plain) {
        $namespace = & $namespaceOf $line
        if ($namespace -eq 'System' -or $namespace.StartsWith('System.')) { $system.Add($line) } else { $other.Add($line) }
    }
    $system.Sort([System.Comparison[string]] { param($a, $b) $comparer.Compare((& $namespaceOf $a), (& $namespaceOf $b)) })
    $other.Sort([System.Comparison[string]] { param($a, $b) $comparer.Compare((& $namespaceOf $a), (& $namespaceOf $b)) })
    $static = @($directives | Where-Object { $_ -match '^using static ' } | Sort-Object { & $namespaceOf $_ })
    $aliases = @($directives | Where-Object { $_ -match '^using \w+\s*=' } | Sort-Object { ($_ -replace '^using (\w+).*', '$1') })

    $sorted = @($system) + @($other) + $static + $aliases
    if (($sorted -join "`n") -ceq ($directives -join "`n")) {
        return $Text
    }

    $newline = if ($Text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $before = if ($first -gt 0) { $lines[0..($first - 1)] } else { @() }
    $after = if ($last -lt $lines.Count - 1) { $lines[($last + 1)..($lines.Count - 1)] } else { @() }
    return (@($before) + $sorted + @($after)) -join $newline
}

function Test-IsTextFile([string] $Path) {
    # A NUL byte in the first 8000 bytes marks a binary file, the same heuristic git uses.
    $bytes = [System.IO.File]::ReadAllBytes((Join-Path $root $Path))
    return [System.Array]::IndexOf($bytes, [byte]0, 0, [System.Math]::Min($bytes.Length, 8000)) -lt 0
}

# Set when -Confirm declines a change, so the template-only files are kept and the script can be run again.
$declined = $false

# 1. Template change-log entries: the new repository starts its own history. Deleted first, so they are neither
#    rewritten nor renamed.
$changeLogEntries = @($trackedFiles | Where-Object { $_ -like 'change-log/*.md' -and $_ -ne 'change-log/README.md' })
foreach ($entry in $changeLogEntries) {
    if ($PSCmdlet.ShouldProcess($entry, 'Delete template change-log entry')) {
        git rm --quiet -- "$entry"
        if ($LASTEXITCODE -ne 0) {
            throw "[Initialize-Repository] git rm failed for '$entry'."
        }
    }
    elseif (-not $WhatIfPreference) {
        $declined = $true
    }
}
$trackedFiles = @($trackedFiles | Where-Object { $_ -notin $changeLogEntries })

# 2. File contents.
foreach ($file in $trackedFiles) {
    if (-not (Test-IsTextFile $file)) {
        continue
    }

    $fullPath = Join-Path $root $file
    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $original = [System.IO.File]::ReadAllText($fullPath)
    if ([string]::IsNullOrEmpty($original)) {
        continue
    }

    $updated = $original
    if ($file -eq 'README.md') {
        $updated = [regex]::Replace($updated, $TemplateOnlyPattern, [string]::Empty)
    }
    $updated = Convert-TemplateToken $updated
    if ($file -like '*.cs' -and $updated -cne $original) {
        $updated = Format-UsingDirective $updated
    }

    if ($updated -ceq $original) {
        continue
    }

    if ($PSCmdlet.ShouldProcess($file, 'Replace template placeholders')) {
        # Text files in the template are UTF-8; keep a byte-order mark only where the file already had one.
        # Line endings are untouched because only the placeholder text is replaced.
        [System.IO.File]::WriteAllText($fullPath, $updated, [System.Text.UTF8Encoding]::new($hasBom))
    }
    elseif (-not $WhatIfPreference) {
        $declined = $true
    }
}

# 3. File and directory names, deepest first so that renaming a directory never invalidates a pending path.
$pathsToRename = $trackedFiles |
    ForEach-Object {
        $segments = $_ -split '/'
        for ($i = 1; $i -le $segments.Count; $i++) {
            ($segments[0..($i - 1)] -join '/')
        }
    } |
    Where-Object { (Split-Path $_ -Leaf) -cmatch $anyTokenPattern } |
    Sort-Object -Unique |
    Sort-Object { ($_ -split '/').Count } -Descending

foreach ($path in $pathsToRename) {
    $leaf = Split-Path $path -Leaf
    $newLeaf = Convert-TemplateToken $leaf
    $parent = Split-Path $path -Parent
    $newPath = if ($parent) { "$parent/$newLeaf" } else { $newLeaf }
    if ($PSCmdlet.ShouldProcess($path, "Rename to $newLeaf")) {
        git mv -- "$path" "$newPath"
        if ($LASTEXITCODE -ne 0) {
            throw "[Initialize-Repository] git mv failed for '$path'."
        }
    }
    elseif (-not $WhatIfPreference) {
        $declined = $true
    }
}

# 4. The template-only files, including this script: a repository is initialised exactly once. They are kept when a
#    change was declined, because placeholders remain and the script is needed to finish the job.
if ($declined) {
    Write-Warning '[Initialize-Repository] Some changes were declined, so placeholders remain. The template files are kept; run the script again to finish.'
}
elseif (-not $KeepScript) {
    foreach ($file in $templateOnlyFiles | Where-Object { Test-Path -LiteralPath $_ }) {
        if ($PSCmdlet.ShouldProcess($file, 'Delete template-only file')) {
            git rm --quiet -- "$file"
            if ($LASTEXITCODE -ne 0) {
                throw "[Initialize-Repository] git rm failed for '$file'; delete it manually."
            }
        }
    }
}

if (-not $WhatIfPreference -and -not $declined) {
    Write-Information @"
[Initialize-Repository] Initialised as $Name ($RepositoryName).

Next steps:
  1. Review the changes:      git status; git diff --cached; git diff   (undo: git reset --hard HEAD)
  2. Build and test:          dotnet build -c Release; dotnet test -c Release
  3. Commit:                  git add --all; git commit -m "chore: initialise repository from template"
  4. Finish the owner setup in README.md (SonarCloud project, secrets, branch protection).
"@ -InformationAction Continue
}
