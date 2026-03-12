param(
    [Parameter(Mandatory = $true)]
    [string]$Query,

    [string]$SourceRoot = "C:\astrbot\AstrBot",

    [int]$MaxResults = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceRoot)) {
    throw "AstrBot source root not found: $SourceRoot"
}

$searchRoots = @(
    @{ Kind = "source"; Path = (Join-Path $SourceRoot "astrbot") },
    @{ Kind = "docs"; Path = (Join-Path $SourceRoot "docs") }
) | Where-Object { Test-Path -LiteralPath $_.Path }

$results = @()

foreach ($root in $searchRoots) {
    if (Get-Command rg -ErrorAction SilentlyContinue) {
        $rgOutput = & rg --color never --line-number --with-filename --smart-case --fixed-strings --glob '!**/.git/**' --glob '!**/__pycache__/**' --glob '!**/.venv/**' --glob '!**/node_modules/**' $Query $root.Path 2>$null
        foreach ($line in $rgOutput) {
            if ($line -match '^(.*?):(\d+):(.*)$') {
                $results += [pscustomobject]@{
                    kind = $root.Kind
                    path = $Matches[1]
                    line = [int]$Matches[2]
                    text = $Matches[3].Trim()
                }
            }
        }
        continue
    }

    $files = Get-ChildItem -LiteralPath $root.Path -Recurse -File |
        Where-Object { $_.FullName -notmatch '\\(\.git|__pycache__|node_modules|\.venv)\\' }

    foreach ($file in $files) {
        $hits = Select-String -Path $file.FullName -Pattern $Query -SimpleMatch
        foreach ($hit in $hits) {
            $results += [pscustomobject]@{
                kind = $root.Kind
                path = $file.FullName
                line = [int]$hit.LineNumber
                text = $hit.Line.Trim()
            }
        }
    }
}

$ordered = $results |
    Sort-Object @{ Expression = { if ($_.kind -eq "source") { 0 } else { 1 } } }, path, line |
    Select-Object -First $MaxResults

$ordered | ConvertTo-Json -Depth 4
