# Dependency-free Windows installer integration tests. Never uses user config.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path $PSScriptRoot -Parent
$installer = Join-Path $repo 'install.ps1'
$shell = (Get-Process -Id $PID).Path
$work = Join-Path ([IO.Path]::GetTempPath()) ('opencode-team-install-' + [guid]::NewGuid().ToString('N'))
$oldPath = $env:PATH
$oldConfig = $env:OPENCODE_CONFIG_DIR
$oldProfile = $env:USERPROFILE
$utf8 = New-Object Text.UTF8Encoding($false)
$script:assertions = 0

function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:assertions++
}
function Write-Text([string]$Path, [string]$Text) {
    [IO.Directory]::CreateDirectory((Split-Path $Path -Parent)) | Out-Null
    [IO.File]::WriteAllText($Path, $Text, $utf8)
}
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
function Run-Installer([string]$Config, [string[]]$Arguments = @(), [bool]$Success = $true, [string]$StartDirectory = '') {
    $env:OPENCODE_CONFIG_DIR = $Config
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $shell
    $start.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $installer + '" ' + ($Arguments -join ' ')
    if ($StartDirectory) {
        $start.WorkingDirectory = $StartDirectory
        $command = "Set-Location -LiteralPath '" + (Get-Location).Path.Replace("'", "''") + "'; `$global:LASTEXITCODE = 0; & '" + $installer.Replace("'", "''") + "' " + ($Arguments -join ' ') + '; exit $LASTEXITCODE'
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
    Assert (($code -eq 0) -eq $Success) "installer $Arguments exit $code (expected success=$Success): $output"
    return ($output -join "`n")
}
function Assert-Link([string]$Path, [string]$Target) {
    $item = Get-Item -LiteralPath $Path -Force
    Assert ($item.LinkType -eq 'SymbolicLink') "$Path must be a symbolic link"
    Assert ([IO.Path]::GetFullPath([string]@($item.Target)[0]) -eq [IO.Path]::GetFullPath($Target)) "$Path target must be $Target"
}
function Fake-Version([string]$Version = '1.19.4', [int]$Code = 0) {
    Write-Text (Join-Path $work 'bin/opencode.cmd') "@echo off`r`necho $Version`r`nexit /b $Code`r`n"
}

try {
    Assert (Test-Path -LiteralPath $installer) 'install.ps1 must exist'
    [IO.Directory]::CreateDirectory($work) | Out-Null
    Fake-Version
    $env:PATH = (Join-Path $work 'bin') + ';' + $env:SystemRoot + '\System32'
    $config = Join-Path $work ('config space ' + [char]0x00F6)
    $json = '{"default_agent":"orchestrator","custom":"preserve"}'
    Write-Text (Join-Path $config 'opencode.json') $json
    Write-Host 'install / repeat / check / uninstall'
    Run-Installer $config | Out-Null
    Run-Installer $config | Out-Null
    foreach ($name in @('agents','commands','team.yaml','team/AGENTS.md')) {
        Assert-Link (Join-Path $config $name) (Join-Path $repo $name)
    }
    foreach ($skill in Get-ChildItem (Join-Path $repo 'skills/team-*') -Directory) {
        Assert-Link (Join-Path $config ('skills/' + $skill.Name)) $skill.FullName
    }
    Run-Installer $config @('-Check') | Out-Null
    Assert ([IO.File]::ReadAllText((Join-Path $config 'opencode.json')) -ceq $json) 'JSON must remain byte-for-byte unchanged'
    Run-Installer $config @('-Uninstall') | Out-Null
    Assert (-not (Test-Path (Join-Path $config 'agents'))) 'uninstall must remove managed link'
    Assert (Test-Path (Join-Path $repo 'agents/orchestrator.md')) 'uninstall must preserve target'
    Assert (Test-Path (Join-Path $config 'opencode.json')) 'uninstall must preserve JSON'
    Run-Installer $config @('-Check') $false | Out-Null

    Write-Host 'local skill collision and in-repository relink'
    $collision = Join-Path $work 'collision'
    Write-Text (Join-Path $collision 'skills/team-build/marker') 'keep'
    [IO.Directory]::CreateDirectory($collision) | Out-Null
    New-Item -ItemType SymbolicLink -Path (Join-Path $collision 'agents') -Target (Join-Path $repo 'team') | Out-Null
    Run-Installer $collision | Out-Null
    Assert-Link (Join-Path $collision 'agents') (Join-Path $repo 'agents')
    Assert ([IO.File]::ReadAllText((Join-Path $collision 'skills/team-build/marker')) -eq 'keep') 'local skill must survive'
    Run-Installer $collision @('-Check') | Out-Null
    Run-Installer $collision @('-Uninstall') | Out-Null
    Assert (Test-Path (Join-Path $collision 'skills/team-build/marker')) 'local skill must survive uninstall'

    Write-Host 'external link protection'
    $external = Join-Path $work 'external'
    Write-Text (Join-Path $external 'marker') 'keep'
    $protected = Join-Path $work 'protected'
    [IO.Directory]::CreateDirectory($protected) | Out-Null
    New-Item -ItemType SymbolicLink -Path (Join-Path $protected 'agents') -Target $external | Out-Null
    Run-Installer $protected @() $false | Out-Null
    Run-Installer $protected @('-Uninstall') | Out-Null
    Assert-Link (Join-Path $protected 'agents') $external
    Assert (Test-Path (Join-Path $external 'marker')) 'external target must survive'
    Assert (-not (Test-Path (Join-Path $protected 'commands'))) 'collision preflight must prevent partial installation'

    Write-Host 'ordinary core files and linked parent containers'
    $ordinary = Join-Path $work 'ordinary'
    Write-Text (Join-Path $ordinary 'agents/marker') 'keep'
    Run-Installer $ordinary @() $false | Out-Null
    Assert (Test-Path (Join-Path $ordinary 'agents/marker')) 'ordinary core directory must survive'
    $parentConfig = Join-Path $work 'linked-parent'
    [IO.Directory]::CreateDirectory($parentConfig) | Out-Null
    New-Item -ItemType SymbolicLink -Path (Join-Path $parentConfig 'skills') -Target $external | Out-Null
    Run-Installer $parentConfig @() $false | Out-Null
    Run-Installer $parentConfig @('-Uninstall') $false | Out-Null
    Assert (-not (Test-Path (Join-Path $external 'team-build'))) 'must not install through linked parent'

    Write-Host 'relative external links and dangling links'
    $relative = Join-Path $work 'relative'
    [IO.Directory]::CreateDirectory($relative) | Out-Null
    # mklink supports relative directory targets in Windows PowerShell 5.1 too.
    & $env:ComSpec /d /c "mklink /D `"$relative\agents`" `"..\external`"" | Out-Null
    Assert ($LASTEXITCODE -eq 0) 'relative link fixture must exist'
    Run-Installer $relative @() $false | Out-Null
    Run-Installer $relative @('-Uninstall') | Out-Null
    Assert ((Get-Item -LiteralPath (Join-Path $relative 'agents')).LinkType -eq 'SymbolicLink') 'relative external link must survive'
    $dangling = Join-Path $work 'dangling'
    [IO.Directory]::CreateDirectory($dangling) | Out-Null
    Write-Text (Join-Path $work 'missing.yaml') 'temporary target'
    New-Item -ItemType SymbolicLink -Path (Join-Path $dangling 'team.yaml') -Target (Join-Path $work 'missing.yaml') | Out-Null
    [IO.File]::Delete((Join-Path $work 'missing.yaml'))
    Run-Installer $dangling @() $false | Out-Null
    Run-Installer $dangling @('-Uninstall') | Out-Null
    Assert ($null -ne (Get-Item -LiteralPath (Join-Path $dangling 'team.yaml') -Force)) 'dangling external link must survive'

    $sibling = Join-Path $work 'prefix-sibling'
    [IO.Directory]::CreateDirectory($sibling) | Out-Null
    & $env:ComSpec /d /c "mklink /D `"$sibling\agents`" `"$repo-other\agents`"" | Out-Null
    Assert ($LASTEXITCODE -eq 0) 'prefix sibling fixture must exist'
    Run-Installer $sibling @() $false | Out-Null
    Run-Installer $sibling @('-Uninstall') | Out-Null
    Assert ($null -ne (Get-Item -LiteralPath (Join-Path $sibling 'agents') -Force)) 'repository-prefix sibling link must survive'

    Write-Host 'version requirements and explicit bootstrap'
    $versionConfig = Join-Path $work 'versions'
    foreach ($version in @('2.0.0','unparseable')) {
        Fake-Version $version
        Run-Installer $versionConfig @() $false | Out-Null
        Run-Installer $versionConfig @('-Check') $false | Out-Null
        Assert (-not (Test-Path $versionConfig)) 'bad version must not create config'
    }
    Fake-Version '1.19.4' 7
    Run-Installer $versionConfig @() $false | Out-Null
    [IO.File]::Delete((Join-Path $work 'bin/opencode.cmd'))
    Run-Installer $versionConfig @() $false | Out-Null
    Run-Installer $versionConfig @('-Uninstall') | Out-Null
    Run-Installer $versionConfig @('-InstallOpenCode') $false | Out-Null
    Fake-Version
    [IO.File]::Copy((Join-Path $work 'bin/opencode.cmd'), (Join-Path $work 'bin/installed.cmd'))
    $npm = "@echo off`r`necho %* > `"%~dp0npm-args.txt`"`r`ncopy /y `"%~dp0installed.cmd`" `"%~dp0opencode.cmd`" >nul`r`nexit /b 0`r`n"
    Write-Text (Join-Path $work 'bin/npm.cmd') $npm
    Run-Installer $versionConfig @('-InstallOpenCode') | Out-Null
    Assert (-not (Test-Path (Join-Path $work 'bin/npm-args.txt'))) 'valid 1.x must not invoke npm'
    [IO.File]::Delete((Join-Path $work 'bin/opencode.cmd'))
    Run-Installer $versionConfig @('-InstallOpenCode') | Out-Null
    Assert (([IO.File]::ReadAllText((Join-Path $work 'bin/npm-args.txt'))).Trim() -eq 'install --global opencode-ai@1') 'bootstrap must constrain OpenCode major version'
    [IO.File]::Delete((Join-Path $work 'bin/opencode.cmd'))
    Write-Text (Join-Path $work 'bin/npm.cmd') "@echo off`r`nexit /b 9`r`n"
    Run-Installer $versionConfig @('-InstallOpenCode') $false | Out-Null
    Write-Text (Join-Path $work 'bin/npm.cmd') "@echo off`r`nexit /b 0`r`n"
    Run-Installer $versionConfig @('-InstallOpenCode') $false | Out-Null
    Fake-Version
    Run-Installer $versionConfig @('-Check','-Uninstall') $false | Out-Null
    Run-Installer $versionConfig @('-Check','-InstallOpenCode') $false | Out-Null

    Write-Host 'JSONC hint and caller working directory'
    $jsoncConfig = Join-Path $work 'jsonc'
    $jsonc = "{ // user comment`n `"custom`": true`n}"
    Write-Text (Join-Path $jsoncConfig 'opencode.json') $jsonc
    Push-Location $work
    try { $hint = Run-Installer $jsoncConfig } finally { Pop-Location }
    Assert ($hint -match 'default_agent') 'missing setting must print a configuration hint'
    Assert ([IO.File]::ReadAllText((Join-Path $jsoncConfig 'opencode.json')) -ceq $jsonc) 'JSONC must remain unchanged'

    Write-Host 'default user profile and wrong or unavailable skill targets'
    $env:USERPROFILE = Join-Path $work 'user profile'
    Run-Installer '' | Out-Null
    Assert-Link (Join-Path $env:USERPROFILE '.config/opencode/agents') (Join-Path $repo 'agents')
    $wrong = Join-Path $jsoncConfig 'team.yaml'
    [IO.File]::Delete($wrong)
    New-Item -ItemType SymbolicLink -Path $wrong -Target (Join-Path $repo 'README.md') | Out-Null
    Run-Installer $jsoncConfig @('-Check') $false | Out-Null
    Run-Installer $jsoncConfig | Out-Null
    $brokenSkill = Join-Path $jsoncConfig 'skills/team-build'
    [IO.Directory]::Delete($brokenSkill)
    $skillTarget = Join-Path $work 'external-skill'
    [IO.Directory]::CreateDirectory($skillTarget) | Out-Null
    New-Item -ItemType SymbolicLink -Path $brokenSkill -Target $skillTarget | Out-Null
    [IO.Directory]::Delete($skillTarget)
    Run-Installer $jsoncConfig @('-Check') $false | Out-Null

    Write-Host 'relative config override after Set-Location'
    $relativeRoot = Join-Path $work 'changed-location'
    $relativeProject = Join-Path $relativeRoot 'project'
    Write-Text (Join-Path $relativeRoot 'config/skills') 'outside marker'
    [IO.Directory]::CreateDirectory((Join-Path $relativeProject 'config')) | Out-Null
    Push-Location $relativeProject
    try { Run-Installer 'config' @('-Uninstall') $true $relativeRoot | Out-Null } finally { Pop-Location }
    Assert ([IO.File]::ReadAllText((Join-Path $relativeRoot 'config/skills')) -eq 'outside marker') 'relative override must not use process-start config'

    Write-Host "installer smoke: OK ($script:assertions assertions)"
} finally {
    $env:PATH = $oldPath
    $env:OPENCODE_CONFIG_DIR = $oldConfig
    $env:USERPROFILE = $oldProfile
    if (Test-Path -LiteralPath $work) { Remove-Fixture $work }
}
