#Requires -Version 5.1
<#
.SYNOPSIS
Links OpenCode Team into the native Windows OpenCode configuration.
.EXAMPLE
  .\install.ps1
  .\install.ps1 -Check
  .\install.ps1 -Uninstall
  .\install.ps1 -InstallOpenCode
#>
[CmdletBinding(DefaultParameterSetName = 'Install')]
param(
    [Parameter(ParameterSetName = 'Check', Mandatory = $true)][switch]$Check,
    [Parameter(ParameterSetName = 'Uninstall', Mandatory = $true)][switch]$Uninstall,
    [Parameter(ParameterSetName = 'Install')][switch]$InstallOpenCode
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\', '/')
$config = if ($env:OPENCODE_CONFIG_DIR) { $env:OPENCODE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.config/opencode' }
$config = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($config)
$config = [IO.Path]::GetFullPath($config).TrimEnd('\', '/')
$core = @('agents', 'commands', 'team.yaml', 'team/AGENTS.md')
$skills = @(Get-ChildItem -LiteralPath (Join-Path $repo 'skills') -Directory | Where-Object { $_.Name -like 'team-*' })

function Get-Entry([string]$Path) {
    Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
}
function Test-Link($Entry) {
    return $null -ne $Entry -and [bool]($Entry.Attributes -band [IO.FileAttributes]::ReparsePoint)
}
function Get-LinkTarget($Entry) {
    if (-not (Test-Link $Entry) -or -not $Entry.Target) { return $null }
    $target = [string]@($Entry.Target)[0]
    if ($target.StartsWith('\\?\')) { $target = $target.Substring(4) }
    if (-not [IO.Path]::IsPathRooted($target)) { $target = Join-Path (Split-Path $Entry.FullName -Parent) $target }
    return [IO.Path]::GetFullPath($target).TrimEnd('\', '/')
}
function Test-Owned($Entry) {
    $target = Get-LinkTarget $Entry
    return $null -ne $target -and $target.StartsWith($repo + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}
function Test-AvailableEntry($Entry) {
    # Test-Path may report a dangling directory link as present on Windows.
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $current = $Entry
    while ($null -ne $current -and (Test-Link $current)) {
        $target = Get-LinkTarget $current
        if (-not $target -or -not $seen.Add($target)) { return $false }
        $current = Get-Entry $target
    }
    return $null -ne $current
}
function Assert-RealParents([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        $item = Get-Entry $current
        if ($null -ne $item -and ((Test-Link $item) -or -not $item.PSIsContainer)) {
            throw "Config container must be a real directory, not a file or link: $current. Existing data was left untouched."
        }
        $parent = [IO.Path]::GetDirectoryName($current)
        if ($parent -eq $current) { break }
        $current = $parent
    }
}
function Remove-Link($Entry) {
    # Never recurse: deleting the link itself must not touch its target.
    if ($Entry.PSIsContainer) { [IO.Directory]::Delete($Entry.FullName) } else { [IO.File]::Delete($Entry.FullName) }
}
function Get-OpenCodeVersion {
    $command = Get-Command opencode -ErrorAction SilentlyContinue
    if ($null -eq $command) { return $null }
    try {
        $global:LASTEXITCODE = 0
        $output = (& $command --version 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $output -match '^v?(1\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?)$') { return $Matches[1] }
    } catch { return $null }
    return $null
}
function Require-OpenCode {
    $version = Get-OpenCodeVersion
    if ($version) { Write-Host "  OK OpenCode $version"; return }
    if ($InstallOpenCode) {
        $npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
        if ($null -eq $npm) { throw 'npm is required for -InstallOpenCode. Install Node.js/npm or OpenCode 1.x manually, then rerun.' }
        Write-Host 'Installing OpenCode 1.x using npm. An incompatible OpenCode binary may be replaced.'
        & $npm install --global opencode-ai@1
        if ($LASTEXITCODE -ne 0) { throw "npm installation failed (exit $LASTEXITCODE)." }
        $version = Get-OpenCodeVersion
        if ($version) { Write-Host "  OK OpenCode $version"; return }
        throw 'OpenCode 1.x could not be verified after npm installation. Check PATH and restart PowerShell.'
    }
    throw 'A working OpenCode 1.x executable is required on PATH. Run opencode --version, or rerun .\install.ps1 -InstallOpenCode. OpenCode 2 is not supported.'
}
function Show-ConfigHint {
    $jsonPath = Join-Path $config 'opencode.json'
    if ([IO.File]::Exists($jsonPath) -and [IO.File]::ReadAllText($jsonPath) -match '"default_agent"\s*:\s*"orchestrator"') {
        Write-Host '  OK opencode.json: default_agent is orchestrator'
        return
    }
    Write-Host "Add these recommended settings to $jsonPath (merge with your existing configuration):"
    [ordered]@{
        '$schema' = 'https://opencode.ai/config.json'
        default_agent = 'orchestrator'
        instructions = @((Join-Path $config 'team/AGENTS.md').Replace('\', '/'), (Join-Path $config 'team.yaml').Replace('\', '/'))
    } | ConvertTo-Json -Depth 3 | Write-Host
}
function Assert-CoreEntry([string]$Name) {
    $entry = Get-Entry (Join-Path $config $Name)
    if ($null -ne $entry -and -not (Test-Owned $entry)) {
        throw "Core entry $Name already exists locally or points outside this repo. Left untouched: $($entry.FullName)"
    }
}
function Install-Link([string]$Name, [bool]$Skill = $false) {
    $path = Join-Path $config $Name
    $target = Join-Path $repo $Name
    $entry = Get-Entry $path
    if ($null -ne $entry) {
        if (-not (Test-Owned $entry)) {
            if ($Skill) { Write-Host "  SKIP $Name (local or externally managed)"; return }
            throw "Existing entry is not managed by this repo: $path"
        }
        if ((Get-LinkTarget $entry) -eq $target) { Write-Host "  OK $Name (already linked)"; return }
        Remove-Link $entry
    }
    New-Item -ItemType SymbolicLink -Path $path -Target $target | Out-Null
    Write-Host "  OK $Name -> $target"
}

try {
    # Validate parents in every mode, including uninstall, before traversing them.
    Assert-RealParents $config
    Assert-RealParents (Join-Path $config 'skills')
    Assert-RealParents (Join-Path $config 'team')
    if ($Uninstall) {
        $names = @($core) + @($skills | ForEach-Object { 'skills/' + $_.Name })
        # Also remove managed skills no longer present in the current checkout.
        if (Test-Path -LiteralPath (Join-Path $config 'skills')) {
            $names += @(Get-ChildItem -LiteralPath (Join-Path $config 'skills') -Force | Where-Object { $_.Name -like 'team-*' } | ForEach-Object { 'skills/' + $_.Name })
        }
        foreach ($name in $names | Select-Object -Unique) {
            $entry = Get-Entry (Join-Path $config $name)
            if (Test-Owned $entry) { Remove-Link $entry; Write-Host "  OK removed $name" }
        }
        Write-Host 'opencode.json was not modified.'
        exit 0
    }
    Require-OpenCode
    if ($Check) {
        $ok = $true
        foreach ($name in $core) {
            $entry = Get-Entry (Join-Path $config $name)
            if ((Test-Link $entry) -and (Get-LinkTarget $entry) -eq (Join-Path $repo $name) -and (Test-Path -LiteralPath (Join-Path $repo $name))) {
                Write-Host "  OK $name"
            } else { Write-Host "  MISSING or wrong target: $name"; $ok = $false }
        }
        foreach ($skill in $skills) {
            $name = 'skills/' + $skill.Name
            $entry = Get-Entry (Join-Path $config $name)
            if (-not (Test-AvailableEntry $entry)) { Write-Host "  MISSING $name"; $ok = $false }
            elseif ((Test-Owned $entry) -and ((Get-LinkTarget $entry) -ne $skill.FullName -or -not (Test-Path -LiteralPath $entry.FullName))) {
                Write-Host "  WRONG target: $name"; $ok = $false
            } else { Write-Host "  OK $name (local/external entries are preserved)" }
        }
        Show-ConfigHint
        if (-not $ok) { exit 1 }
        exit 0
    }
    foreach ($name in $core) { Assert-CoreEntry $name }
    [IO.Directory]::CreateDirectory($config) | Out-Null
    # Probe before replacing or creating any installation links.
    $probe = Join-Path $config ('.opencode-team-link-probe-' + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType SymbolicLink -Path $probe -Target (Join-Path $repo 'team.yaml') | Out-Null
    } catch {
        throw 'Cannot create symbolic links. Run this installer from an Administrator PowerShell, or enable Windows Developer Mode and use PowerShell 7. No installation links were changed.'
    } finally { if ($null -ne (Get-Entry $probe)) { [IO.File]::Delete($probe) } }
    [IO.Directory]::CreateDirectory((Join-Path $config 'skills')) | Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $config 'team')) | Out-Null
    foreach ($name in $core) { Install-Link $name }
    foreach ($skill in $skills) { Install-Link ('skills/' + $skill.Name) $true }
    Show-ConfigHint
    Write-Host 'Restart OpenCode. opencode.json was not modified.'
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
