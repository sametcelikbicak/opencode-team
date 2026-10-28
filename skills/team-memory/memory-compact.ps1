#Requires -Version 5.1
# Compact project memory from the target project's working directory.
[CmdletBinding()]
param([Parameter(Position = 0)][string]$Role)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$roles = @('analyst','pm','po','ux','brand','architect','fe','be','qa','security','docs','devops','marketing','orchestrator')
$memory = if ($env:MEMORY_DIR) { $env:MEMORY_DIR } else { Join-Path (Get-Location).Path '.team/memory' }
$memory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($memory)
$memory = [IO.Path]::GetFullPath($memory).TrimEnd('\', '/')
$utf8 = New-Object Text.UTF8Encoding($false)

function Assert-SafePath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if ($full -ne $memory -and -not $full.StartsWith($memory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes the memory directory: $Path"
    }
    # Reparse points could redirect writes outside the selected memory tree.
    $current = $full
    while ($current) {
        $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($null -ne $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Linked memory paths are not supported: $current"
        }
        $parent = [IO.Path]::GetDirectoryName($current)
        if ($parent -eq $current) { break }
        $current = $parent
    }
}
function Write-MemoryLines([string]$Path, [string[]]$Lines) {
    Assert-SafePath $Path
    $temporary = $Path + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    try {
        [IO.File]::WriteAllLines($temporary, $Lines, $utf8)
        if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temporary, $Path, [NullString]::Value) }
        else { [IO.File]::Move($temporary, $Path) }
    } finally { if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) } }
}
function Compact-Log([string]$Name) {
    $log = Join-Path $memory ('log/' + $Name + '.md')
    Assert-SafePath $log
    if (-not [IO.File]::Exists($log)) { return }
    $lines = [IO.File]::ReadAllLines($log)
    $entries = @($lines | Where-Object { $_ -match '^-\s' })
    if ($entries.Count -le 40) { return }
    $archiveCount = $entries.Count - 10
    $groups = [ordered]@{}
    for ($i = 0; $i -lt $archiveCount; $i++) {
        $entry = $entries[$i]
        $date = [datetime]::MinValue
        if ($entry -notmatch '^-\s+(\d{4}-\d{2}-\d{2})\s+\|' -or
            -not [datetime]::TryParseExact($Matches[1], 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$date)) {
            throw "Invalid archive date in $Name log; log was left unchanged."
        }
        $month = $date.ToString('yyyy-MM', [Globalization.CultureInfo]::InvariantCulture)
        if (-not $groups.Contains($month)) { $groups[$month] = New-Object 'Collections.Generic.List[string]' }
        $groups[$month].Add($entry)
    }
    $archiveDir = Join-Path $memory 'archive'
    Assert-SafePath $archiveDir
    foreach ($month in $groups.Keys) { Assert-SafePath (Join-Path $archiveDir ("$Name-$month.md")) }
    [IO.Directory]::CreateDirectory($archiveDir) | Out-Null
    foreach ($month in $groups.Keys) {
        $archive = Join-Path $archiveDir ("$Name-$month.md")
        $archived = if ([IO.File]::Exists($archive)) { @([IO.File]::ReadAllLines($archive)) } else { @("# $Name archive $([char]0x2014) $month", '') }
        Write-MemoryLines $archive ([string[]]($archived + $groups[$month].ToArray()))
    }
    $retained = @($lines | Select-Object -First 2) + @($entries[$archiveCount..($entries.Count - 1)])
    Write-MemoryLines $log ([string[]]$retained)
    Write-Host "compacted ${Name}: archived $archiveCount entries, kept 10"
}
function Compact-Index {
    $index = Join-Path $memory 'INDEX.md'
    Assert-SafePath $index
    if (-not [IO.File]::Exists($index)) { return }
    $lines = [IO.File]::ReadAllLines($index)
    if ($lines.Count -le 60) { return }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $unique = @($lines | Where-Object { $seen.Add($_) })
    if ($unique.Count -gt 60) {
        throw "INDEX.md is $($unique.Count) lines after removing duplicates; merge facts, move detail to a decision file, or shorten open questions, then rerun. Index was left unchanged."
    }
    Write-MemoryLines $index ([string[]]$unique)
    Write-Host "compacted INDEX.md: $($lines.Count) -> $($unique.Count) lines"
}
try {
    if ($Role -and ($Role -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_-]*$' -or $Role -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$')) {
        throw "Unsafe role name: $Role. Use letters, digits, underscores or hyphens and avoid Windows device names."
    }
    Assert-SafePath $memory
    $selected = if ($Role) { @($Role) } else { $roles }
    foreach ($name in $selected) { Compact-Log $name }
    Compact-Index
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
