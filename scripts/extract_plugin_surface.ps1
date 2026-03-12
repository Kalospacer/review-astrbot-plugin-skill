param(
    [Parameter(Mandatory = $true)]
    [string]$PluginPath,

    [switch]$AsText
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $PluginPath)) {
    throw "Plugin path not found: $PluginPath"
}

$resolvedPluginPath = (Resolve-Path -LiteralPath $PluginPath).Path
$pythonFiles = Get-ChildItem -LiteralPath $resolvedPluginPath -Recurse -File -Filter *.py |
    Sort-Object FullName

function Get-LineNumber {
    param(
        [string[]]$Lines,
        [int]$Index,
        [string]$Pattern
    )

    for ($i = $Index; $i -ge 0 -and $i -ge ($Index - 5); $i--) {
        if ($Lines[$i] -match $Pattern) {
            return $i + 1
        }
    }

    return $Index + 1
}

$imports = @()
$starClasses = @()
$decorators = @()
$hooks = @()
$llmTools = @()
$dataDirUsages = @()
$syncNetworkCandidates = @()

$hookNames = @(
    "on_astrbot_loaded",
    "on_waiting_llm_request",
    "on_llm_request",
    "on_llm_response",
    "on_decorating_result",
    "after_message_sent",
    "on_using_llm_tool",
    "on_llm_tool_respond"
)

foreach ($file in $pythonFiles) {
    $content = @(Get-Content -LiteralPath $file.FullName)

    for ($index = 0; $index -lt $content.Count; $index++) {
        $line = $content[$index]
        $trimmed = $line.Trim()

        if ($trimmed -match '^from\s+astrbot\.api(?:\.[\w\.]+)?\s+import\s+.+$' -or $trimmed -match '^import\s+astrbot\.api(?:\.[\w\.]+)?(?:\s|$)') {
            $imports += [pscustomobject]@{
                path = $file.FullName
                line = $index + 1
                text = $trimmed
            }
        }

        if ($trimmed -match '^class\s+([A-Za-z_]\w*)\(([^)]*)\)\s*:') {
            $className = $Matches[1]
            $bases = $Matches[2]
            if ($bases -match '(^|,\s*)(Star)(\s*,|$)') {
                $starClasses += [pscustomobject]@{
                    path = $file.FullName
                    line = $index + 1
                    class_name = $className
                    bases = $bases
                }
            }
        }

        if ($trimmed -match '^@filter\.([A-Za-z_]\w*)') {
            $decorators += [pscustomobject]@{
                path = $file.FullName
                line = $index + 1
                decorator = $Matches[1]
                text = $trimmed
            }
        }

        if ($trimmed -match 'StarTools\.get_data_dir\s*\(') {
            $dataDirUsages += [pscustomobject]@{
                path = $file.FullName
                line = $index + 1
                text = $trimmed
            }
        }

        if ($trimmed -match 'requests\.' -or
            $trimmed -match 'urllib\.request\.' -or
            $trimmed -match 'httpx\.(get|post|put|delete|patch|head|request)\s*\(' -or
            $trimmed -match 'httpx\.Client\s*\(' -or
            $trimmed -match 'urllib3\.' -or
            $trimmed -match '\bSession\s*\(') {
            $syncNetworkCandidates += [pscustomobject]@{
                path = $file.FullName
                line = $index + 1
                text = $trimmed
            }
        }

        if ($trimmed -match '^async\s+def\s+([A-Za-z_]\w*)\s*\((.*)\)\s*:') {
            $name = $Matches[1]
            $signature = $Matches[2]
            $hookDecorator = $null
            for ($probe = $index - 1; $probe -ge 0 -and $probe -ge ($index - 4); $probe--) {
                $decoratorLine = $content[$probe].Trim()
                if ($decoratorLine -match '^@filter\.([A-Za-z_]\w*)') {
                    $candidateDecorator = $Matches[1]
                    if ($hookNames -contains $candidateDecorator) {
                        $hookDecorator = $candidateDecorator
                        break
                    }
                }
            }

            if ($hookNames -contains $name -or $hookDecorator) {
                $hooks += [pscustomobject]@{
                    path = $file.FullName
                    line = $index + 1
                    name = if ($hookDecorator) { $hookDecorator } else { $name }
                    function_name = $name
                    signature = $signature
                }
            }
        }

        $isLlmTool = $false
        for ($probe = $index; $probe -ge 0 -and $probe -ge ($index - 4); $probe--) {
            if ($content[$probe].Trim() -match '^@filter\.llm_tool') {
                $isLlmTool = $true
                break
            }
        }

        if ($isLlmTool -and $trimmed -match '^async\s+def\s+([A-Za-z_]\w*)\s*\((.*)\)\s*:') {
            $docstringPreview = @()
            for ($scan = $index + 1; $scan -lt [Math]::Min($content.Count, $index + 12); $scan++) {
                $candidate = $content[$scan].Trim()
                if (-not $candidate) { continue }
                $docstringPreview += $candidate
                if ($docstringPreview.Count -ge 3) { break }
            }

            $llmTools += [pscustomobject]@{
                path = $file.FullName
                line = $index + 1
                name = $Matches[1]
                signature = $Matches[2]
                docstring_preview = ($docstringPreview -join " ")
            }
        }
    }
}

$metadata = Join-Path $resolvedPluginPath "metadata.yaml"

$result = [pscustomobject]@{
    plugin_path = $resolvedPluginPath
    metadata_yaml = if (Test-Path -LiteralPath $metadata) { $metadata } else { $null }
    python_files = $pythonFiles.FullName
    astrbot_imports = $imports
    star_classes = $starClasses
    filter_decorators = $decorators
    hooks = $hooks
    llm_tools = $llmTools
    get_data_dir_usages = $dataDirUsages
    sync_network_candidates = $syncNetworkCandidates
}

if ($AsText) {
    $result | Format-List | Out-String
} else {
    $result | ConvertTo-Json -Depth 6
}
