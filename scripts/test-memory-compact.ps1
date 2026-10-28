# Dependency-free native memory regression tests. No user memory is touched.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path $PSScriptRoot -Parent
$helper = Join-Path $repo 'skills/team-memory/memory-compact.ps1'
$shell = (Get-Process -Id $PID).Path
$work = Join-Path ([IO.Path]::GetTempPath()) ('opencode-team-memory-' + [guid]::NewGuid().ToString('N'))
$oldMemory = $env:MEMORY_DIR
$utf8 = New-Object Text.UTF8Encoding($false)
$script:assertions = 0
function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:assertions++
}
function Write-Lines([string]$Path, [string[]]$Lines) {
    [IO.Directory]::CreateDirectory((Split-Path $Path -Parent)) | Out-Null
    [IO.File]::WriteAllLines($Path, $Lines, $utf8)
}
function Entries([int]$Start, [int]$End, [string]$Month = '2026-10') {
    for ($i = $Start; $i -le $End; $i++) { '- {0}-{1:00} | research | fact | entry {2} | artifact' -f $Month, (($i - 1) % 28 + 1), $i }
}
function Run-Compactor([string]$Memory, [string]$Role = '', [bool]$Success = $true, [string]$StartDirectory = '') {
    $env:MEMORY_DIR = $Memory
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $shell
    $start.WorkingDirectory = (Get-Location).Path
    $start.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $helper + '"'
    if ($Role) { $start.Arguments += ' -Role "' + $Role + '"' }
    if ($StartDirectory) {
        $start.WorkingDirectory = $StartDirectory
        $command = "Set-Location -LiteralPath '" + (Get-Location).Path.Replace("'", "''") + "'; `$global:LASTEXITCODE = 0; & '" + $helper.Replace("'", "''") + "'"
        if ($Role) { $command += " -Role '" + $Role.Replace("'", "''") + "'" }
        $command += '; exit $LASTEXITCODE'
        $start.Arguments = '-NoProfile -ExecutionPolicy Bypass -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    }
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $process = [Diagnostics.Process]::Start($start)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $output = $stdout.Result + $stderr.Result
    $code = $process.ExitCode
    $process.Dispose()
    Assert (($code -eq 0) -eq $Success) "compactor exit $code (expected success=$Success): $output"
}
function Count-Entries([string]$Path) { return @([IO.File]::ReadAllLines($Path) | Where-Object { $_ -match '^-\s' }).Count }
function Remove-Fixture([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) { return }
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        if ($item.PSIsContainer) { [IO.Directory]::Delete($Path) } else { [IO.File]::Delete($Path) }
    } elseif ($item.PSIsContainer) {
        foreach ($child in Get-ChildItem -LiteralPath $Path -Force) { Remove-Fixture $child.FullName }
        [IO.Directory]::Delete($Path)
    } else { [IO.File]::Delete($Path) }
}
try {
    Assert (Test-Path -LiteralPath $helper) 'memory-compact.ps1 must exist'
    $memory = Join-Path $work ('project space ' + [char]0x00F6)
    $log = Join-Path $memory 'log/analyst.md'
    Write-Host 'empty logs and 40-entry boundary'
    Write-Lines $log @('# analyst log', '')
    Run-Compactor $memory 'analyst'
    Write-Lines $log (@('# analyst log', '') + @(Entries 1 40))
    $before = [IO.File]::ReadAllText($log)
    Run-Compactor $memory 'analyst'
    Assert ([IO.File]::ReadAllText($log) -ceq $before) '40 entries must remain unchanged'

    Write-Host 'archive 35 / retain 10 and repeated monthly archive'
    Write-Lines $log (@('# analyst log', '') + @(Entries 1 45))
    Run-Compactor $memory 'analyst'
    $archive = Join-Path $memory 'archive/analyst-2026-10.md'
    Assert ((Count-Entries $log) -eq 10) '45 entries must retain last 10'
    Assert ((Count-Entries $archive) -eq 35) '45 entries must archive first 35'
    Assert (([IO.File]::ReadAllLines($log))[-1] -match 'entry 45 \|') 'log order must be retained'
    [IO.File]::AppendAllLines($log, [string[]]@(Entries 46 80), $utf8)
    Run-Compactor $memory 'analyst'
    Assert ((Count-Entries $archive) -eq 70) 'second run must append 35 entries'
    Assert (@([IO.File]::ReadAllLines($archive) | Where-Object { $_ -match '^# analyst archive' }).Count -eq 1) 'archive header must not duplicate'
    Run-Compactor $memory 'analyst'
    Assert ((Count-Entries $archive) -eq 70) 'no-op rerun must not duplicate entries'

    Write-Host 'multiple months, CRLF, Unicode, role filter'
    $unicode = 'T' + [char]0x00FC + 'rk' + [char]0x00E7 + 'e'
    $lines = @('# analyst log', '') + @(Entries 1 20 '2026-09') + @(Entries 21 41)
    $lines[2] += ' ' + $unicode
    [IO.File]::WriteAllText($log, ($lines -join "`r`n"), $utf8)
    Write-Lines (Join-Path $memory 'log/pm.md') (@('# pm log', '') + @(Entries 1 41))
    Run-Compactor $memory 'analyst'
    Assert ((Count-Entries (Join-Path $memory 'archive/analyst-2026-09.md')) -eq 20) 'September entries must use September archive'
    Assert ([IO.File]::ReadAllText((Join-Path $memory 'archive/analyst-2026-09.md')).Contains($unicode)) 'Unicode must survive compaction'
    Assert ((Count-Entries (Join-Path $memory 'log/pm.md')) -eq 41) 'explicit role must not compact another role'
    Run-Compactor $memory
    Assert ((Count-Entries (Join-Path $memory 'log/pm.md')) -eq 10) 'no role must compact all known roles'

    Write-Host 'index cap, stable exact deduplication, unchanged failure'
    $index = Join-Path $memory 'INDEX.md'
    Write-Lines $index ([string[]](1..60 | ForEach-Object { "fact $_" }))
    $before = [IO.File]::ReadAllText($index)
    Run-Compactor $memory
    Assert ([IO.File]::ReadAllText($index) -ceq $before) '60-line index must remain unchanged'
    $lines = @('# Memory Index', 'Fact', 'fact', $unicode) + @((1..65) | ForEach-Object { 'duplicate' })
    Write-Lines $index $lines
    Run-Compactor $memory
    Assert ([IO.File]::ReadAllLines($index).Count -eq 5) 'only exact duplicates must be removed'
    Assert (([IO.File]::ReadAllLines($index))[1] -ceq 'Fact') 'first occurrence order must remain'
    Write-Lines $index ([string[]](1..61 | ForEach-Object { "unique fact $_" }))
    $before = [IO.File]::ReadAllText($index)
    Run-Compactor $memory '' $false
    Assert ([IO.File]::ReadAllText($index) -ceq $before) 'unique oversized index must remain unchanged'
    [IO.File]::Delete($index)

    Write-Host 'default current-project directory and custom memory root'
    $project = Join-Path $work 'cwd'
    $cwdLog = Join-Path $project '.team/memory/log/analyst.md'
    Write-Lines $cwdLog (@('# analyst log', '') + @(Entries 1 41))
    Push-Location $project
    try { Run-Compactor '' 'analyst' } finally { Pop-Location }
    Assert ((Count-Entries $cwdLog) -eq 10) 'default memory path must use target project CWD'

    Write-Host 'explicit custom role'
    $customLog = Join-Path $memory 'log/researcher.md'
    Write-Lines $customLog (@('# researcher log', '') + @(Entries 1 41))
    Run-Compactor $memory 'researcher'
    Assert ((Count-Entries $customLog) -eq 10) 'explicit safe custom roles must work like the Bash helper'

    Write-Host 'relative memory override after Set-Location'
    $relativeRoot = Join-Path $work 'changed-location'
    $relativeProject = Join-Path $relativeRoot 'project'
    $outsideIndex = Join-Path $relativeRoot 'memory/INDEX.md'
    Write-Lines $outsideIndex ([string[]](1..61 | ForEach-Object { "outside fact $_" }))
    $relativeLog = Join-Path $relativeProject 'memory/log/analyst.md'
    Write-Lines $relativeLog (@('# analyst log', '') + @(Entries 1 41))
    Write-Lines (Join-Path $relativeProject 'memory/INDEX.md') @('current project')
    Push-Location $relativeProject
    try { Run-Compactor 'memory' '' $true $relativeRoot } finally { Pop-Location }
    Assert ((Count-Entries $relativeLog) -eq 10) 'relative memory must use current PowerShell location'
    Assert ([IO.File]::ReadAllLines($outsideIndex).Count -eq 61) 'process-start memory must remain untouched'

    Write-Host 'unsafe role/date and linked memory protection'
    Run-Compactor $memory '../outside' $false
    $badLines = @('# analyst log', '') + @(Entries 1 41)
    $badLines[2] = '- ../escape | research | fact | bad date'
    Write-Lines $log $badLines
    $before = [IO.File]::ReadAllText($log)
    Run-Compactor $memory 'analyst' $false
    Assert ([IO.File]::ReadAllText($log) -ceq $before) 'unsafe archive date must not change log'
    $outside = Join-Path $work 'outside'
    Write-Lines (Join-Path $outside 'analyst.md') (@('# analyst log', '') + @(Entries 1 41))
    $linkedMemory = Join-Path $work 'linked'
    [IO.Directory]::CreateDirectory($linkedMemory) | Out-Null
    New-Item -ItemType SymbolicLink -Path (Join-Path $linkedMemory 'log') -Target $outside | Out-Null
    Run-Compactor $linkedMemory 'analyst' $false
    Assert ((Count-Entries (Join-Path $outside 'analyst.md')) -eq 41) 'linked log container must not change outside memory'
    Write-Host "memory-compact: OK ($script:assertions assertions)"
} finally {
    $env:MEMORY_DIR = $oldMemory
    if (Test-Path -LiteralPath $work) { Remove-Fixture $work }
}
