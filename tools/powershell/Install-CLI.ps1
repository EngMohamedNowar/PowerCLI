<#
.SYNOPSIS
    Installs the PowerCLI professional PowerShell CLI on a fresh Windows machine.

.DESCRIPTION
    Idempotent installer. Safe to run more than once - anything already in place
    is detected and skipped.

    What it does:
      1. Ensures the execution policy allows local scripts
      2. Installs Git and PowerShell 7 via winget (if missing)
      3. Installs the CaskaydiaCove NF Nerd Font for the current user (no admin)
      4. Patches Windows Terminal: Nerd Font + PowerShell 7 as the default profile
      5. Writes the PowerShell profile files
      6. Verifies the result

.EXAMPLE
    # One-liner from the repo root:
    irm https://raw.githubusercontent.com/EngMohamedNowar/PowerCLI/main/tools/powershell/Install-CLI.ps1 | iex

.EXAMPLE
    # Or locally:
    .\tools\powershell\Install-CLI.ps1
#>

param(
    # Skip winget installs (use when the tools are already present).
    [switch]$SkipTools,
    # Skip the Nerd Font download / registration.
    [switch]$SkipFont,
    # Force reinstall of the Nerd Font even if it is already registered.
    [switch]$ForceFont
)


# ---------------------------------------------------------------------------
# Bootstrap: support both "run from file" and "iex (irm ...)" usage.
# When invoked via iex, $PSScriptRoot is empty, so we download the needed
# files from GitHub first.
# ---------------------------------------------------------------------------
# Determine the script root and ensure the needed files are present.
# This works both when run from a file and via iex (irm ...).
$ScriptRoot = $PSScriptRoot
if (-not $ScriptRoot -or -not (Test-Path (Join-Path $ScriptRoot 'PowerCLI.ps1'))) {
    $ScriptRoot = Join-Path $env:TEMP 'PowerCLI-install'
    New-Item -ItemType Directory -Force -Path $ScriptRoot | Out-Null
    New-Item -ItemType Directory -Force -Path "$ScriptRoot\themes" | Out-Null

    $baseUrl = 'https://raw.githubusercontent.com/EngMohamedNowar/PowerCLI/main/tools/powershell'
    Write-Host 'Downloading PowerCLI files...' -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri "$baseUrl/PowerCLI.ps1" -OutFile "$ScriptRoot\PowerCLI.ps1" -UseBasicParsing -ErrorAction Stop
        Invoke-WebRequest -Uri "$baseUrl/themes/powercli.omp.json" -OutFile "$ScriptRoot\themes\powercli.omp.json" -UseBasicParsing -ErrorAction Stop
        Write-Host 'Downloaded.' -ForegroundColor Green
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Clone the repo instead: git clone https://github.com/EngMohamedNowar/PowerCLI.git" -ForegroundColor Yellow
        return
    }
}

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$RepoRoot   = if ($ScriptRoot -and (Test-Path (Join-Path $ScriptRoot '..\..'))) { (Resolve-Path (Join-Path $ScriptRoot '..\..')).Path } else { $ScriptRoot }
$ProfileSrc = Join-Path $ScriptRoot 'PowerCLI.ps1'

$SharedDir  = Join-Path $env:USERPROFILE 'Documents\PowerShell'
$SharedFile = Join-Path $SharedDir 'PowerCLI.ps1'
$ThemeDir   = Join-Path $SharedDir 'themes'
$PwshBoot   = Join-Path $SharedDir 'Microsoft.PowerShell_profile.ps1'
$WinPsBoot  = Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'

$FontDir    = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$FontRegKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
$WtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'

$NerdFontFamily = 'CaskaydiaCove NF'
$NerdFontUrl    = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/CascadiaCode.zip'

$FontFiles = [ordered]@{
    'CaskaydiaCoveNerdFont-Regular.ttf'    = 'CaskaydiaCove NF Regular (TrueType)'
    'CaskaydiaCoveNerdFont-Bold.ttf'       = 'CaskaydiaCove NF Bold (TrueType)'
    'CaskaydiaCoveNerdFont-Italic.ttf'     = 'CaskaydiaCove NF Italic (TrueType)'
    'CaskaydiaCoveNerdFont-BoldItalic.ttf' = 'CaskaydiaCove NF Bold Italic (TrueType)'
    'CaskaydiaCoveNerdFontMono-Regular.ttf' = 'CaskaydiaCove NFM Regular (TrueType)'
    'CaskaydiaCoveNerdFontMono-Bold.ttf'    = 'CaskaydiaCove NFM Bold (TrueType)'
}

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
function Write-Step  { param([string]$Text) Write-Host "`n==> $Text" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Text) Write-Host "    [OK]   $Text" -ForegroundColor Green }
function Write-Info  { param([string]$Text) Write-Host "    [info] $Text" -ForegroundColor DarkGray }
function Write-Warn2 { param([string]$Text) Write-Host "    [warn] $Text" -ForegroundColor Yellow }
function Write-Fail  { param([string]$Text) Write-Host "    [FAIL] $Text" -ForegroundColor Red }

Write-Host ''
Write-Host '  ================================================' -ForegroundColor Cyan
Write-Host '   PowerCLI installer' -ForegroundColor Cyan
Write-Host '  ================================================' -ForegroundColor Cyan
Write-Host "   Repo: $RepoRoot"

# ---------------------------------------------------------------------------
# 1. Execution policy
# ---------------------------------------------------------------------------
Write-Step 'Execution policy'
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq 'Undefined' -or $policy -eq 'Restricted') {
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force | Out-Null
        Write-Ok 'Set to RemoteSigned (CurrentUser)'
    } catch {
        Write-Warn2 "Could not change policy: $($_.Exception.Message)"
    }
} else {
    Write-Ok "Already '$policy' (CurrentUser)"
}

# ---------------------------------------------------------------------------
# 2. Tools: Git + PowerShell 7
# ---------------------------------------------------------------------------
Write-Step 'Developer tools'

function Test-CommandPresent([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction Ignore)
}

function Install-WingetPackage {
    param([string]$Id, [string]$Label)
    if (-not (Test-CommandPresent 'winget')) {
        Write-Warn2 "winget not available - install '$Label' manually"
        return
    }
    Write-Info "installing $Label ..."
    $args = @(
        'install', '--id', $Id, '-e', '--source', 'winget',
        '--accept-package-agreements', '--accept-source-agreements',
        '--silent', '--disable-interactivity'
    )
    & winget @args 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Ok "$Label installed" }
    else { Write-Warn2 "$Label install returned exit code $LASTEXITCODE - install it manually" }
}

if (-not $SkipTools) {
    if (Test-CommandPresent 'git') {
        Write-Ok "Git already present ($(& git --version))"
    } else {
        Install-WingetPackage -Id 'Git.Git' -Label 'Git'
    }

    if (Test-CommandPresent 'pwsh') {
        Write-Ok "PowerShell 7 already present"
    } else {
        Install-WingetPackage -Id 'Microsoft.PowerShell' -Label 'PowerShell 7'
    }

    # Oh-My-Posh (prompt engine)
    if (Test-CommandPresent 'oh-my-posh') {
        Write-Ok "Oh-My-Posh already present ($(& oh-my-posh --version))"
    } else {
        Install-WingetPackage -Id 'JanDeDobbeleer.OhMyPosh' -Label 'Oh-My-Posh'
    }
} else {
    Write-Info 'tool installation skipped (-SkipTools)'
}

# ---------------------------------------------------------------------------
# 3. Nerd Font (per-user, no admin required)
# ---------------------------------------------------------------------------
Write-Step 'Nerd Font (prompt icons)'

$fontInstalled = (Get-ItemProperty -Path $FontRegKey -ErrorAction Ignore |
                   Get-Member -MemberType NoteProperty |
                   Where-Object { $_.Name -like "$NerdFontFamily *" }) -ne $null

if ($SkipFont) {
    Write-Info 'font installation skipped (-SkipFont)'
} elseif ($fontInstalled -and -not $ForceFont) {
    Write-Ok "$NerdFontFamily already registered"
} else {
    $tmpZip  = Join-Path $env:TEMP 'CascadiaCode.zip'
    $tmpFont = Join-Path $env:TEMP 'CaskaydiaCoveFonts'
    try {
        Write-Info 'downloading CascadiaCode.zip (54 MB) ...'
        Invoke-WebRequest -Uri $NerdFontUrl -OutFile $tmpZip -UseBasicParsing -TimeoutSec 300
        Write-Ok ('downloaded ({0:N1} MB)' -f ((Get-Item $tmpZip).Length / 1MB))

        Remove-Item $tmpFont -Recurse -Force -ErrorAction Ignore
        Expand-Archive -Path $tmpZip -DestinationPath $tmpFont -Force

        New-Item -ItemType Directory -Force -Path $FontDir | Out-Null
        if (-not (Test-Path $FontRegKey)) { New-Item -Path $FontRegKey -Force | Out-Null }

        $installed = 0
        foreach ($file in $FontFiles.Keys) {
            $src = Join-Path $tmpFont $file
            if (-not (Test-Path $src)) { continue }
            $dst = Join-Path $FontDir $file
            Copy-Item $src $dst -Force
            New-ItemProperty -Path $FontRegKey -Name $FontFiles[$file] -Value $dst `
                             -PropertyType String -Force | Out-Null
            $installed++
        }
        if ($installed -gt 0) {
            Write-Ok "$installed font files installed for the current user"
            # Tell running apps that the font set changed.
            try {
                Add-Type -Namespace Win -Name F -MemberDefinition @'
[DllImport("user32.dll", SetLastError=true)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam,
    IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
'@
                $res = [IntPtr]::Zero
                [Win.F]::SendMessageTimeout([IntPtr]0xffff, 0x001D, [IntPtr]::Zero,
                    [IntPtr]::Zero, 2, 1000, [ref]$res) | Out-Null
                Write-Ok 'WM_FONTCHANGE broadcast sent'
            } catch {
                Write-Warn2 'could not broadcast WM_FONTCHANGE (harmless)'
            }
        } else {
            Write-Fail 'no font files found in the archive'
        }
    } catch {
        Write-Fail "font installation failed: $($_.Exception.Message)"
        Write-Info "download it manually: $NerdFontUrl"
    } finally {
        Remove-Item $tmpZip  -Force -ErrorAction Ignore
        Remove-Item $tmpFont -Recurse -Force -ErrorAction Ignore
    }
}

# ---------------------------------------------------------------------------
# 4. Windows Terminal settings
# ---------------------------------------------------------------------------
Write-Step 'Windows Terminal settings'

if (-not (Test-Path $WtSettings)) {
    Write-Warn2 "settings.json not found at $WtSettings"
    Write-Info 'Install Windows Terminal, then re-run this script to patch it'
} else {
    try {
        Copy-Item $WtSettings "$WtSettings.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Force
        Write-Ok 'settings.json backed up'

        $wt = Get-Content $WtSettings -Raw | ConvertFrom-Json

        # --- font ---
        if (-not $wt.profiles) { $wt | Add-Member -NotePropertyName 'profiles' -NotePropertyValue ([pscustomobject]@{}) }
        if (-not $wt.profiles.defaults) { $wt.profiles | Add-Member -NotePropertyName 'defaults' -NotePropertyValue ([pscustomobject]@{}) }
        if ($wt.profiles.defaults.fontFace) {
            if ($wt.profiles.defaults.fontFace -ne $NerdFontFamily) {
                $wt.profiles.defaults.fontFace = $NerdFontFamily
                Write-Ok "fontFace set to '$NerdFontFamily'"
            } else {
                Write-Ok "fontFace already '$NerdFontFamily'"
            }
        } else {
            $wt.profiles.defaults | Add-Member -NotePropertyName 'fontFace' -NotePropertyValue $NerdFontFamily
            Write-Ok "fontFace set to '$NerdFontFamily'"
        }

        # --- soft, eye-friendly terminal palette ---
        # Pure black (#0C0C0C) + pure white is harsh over long sessions.
        # Nord-based greys reduce halation without washing anything out.
        $palette = [ordered]@{
            'background'          = '#1C1C1C'
            'foreground'          = '#D8DEE9'
            'cursorColor'         = '#88C0D0'
            'selectionBackground' = '#3B4252'
        }
        foreach ($key in $palette.Keys) {
            $current = if ($wt.profiles.defaults.PSObject.Properties.Name -contains $key) { $wt.profiles.defaults.$key } else { $null }
            if ($current -ne $palette[$key]) {
                if ($wt.profiles.defaults.PSObject.Properties.Name -contains $key) {
                    $wt.profiles.defaults.$key = $palette[$key]
                } else {
                    $wt.profiles.defaults | Add-Member -NotePropertyName $key -NotePropertyValue $palette[$key]
                }
                Write-Ok "$key set to $($palette[$key])"
            } else {
                Write-Ok "$key already $($palette[$key])"
            }
        }

        # --- default profile: prefer PowerShell 7 ---
        $pwshProfile = $wt.profiles.list | Where-Object { $_.source -eq 'Windows.Terminal.PowershellCore' } | Select-Object -First 1
        if ($pwshProfile) {
            if ($wt.defaultProfile -ne $pwshProfile.guid) {
                $wt.defaultProfile = $pwshProfile.guid
                Write-Ok "default profile switched to PowerShell 7 ($($pwshProfile.guid))"
            } else {
                Write-Ok 'PowerShell 7 is already the default profile'
            }

            # Suppress the 'PowerShell 7.7.0' startup banner.
            if ($pwshProfile.commandline -ne '%LOCALAPPDATA%\\Microsoft\\WindowsApps\\pwsh.exe -NoLogo') {
                $pwshProfile.commandline = '%LOCALAPPDATA%\\Microsoft\\WindowsApps\\pwsh.exe -NoLogo'
                Write-Ok 'added -NoLogo to the PowerShell 7 profile'
            }
        } else {
            Write-Info 'no PowerShell 7 profile in Terminal yet - skipping default profile change'
        }

        # Windows Terminal requires UTF-8 *without* a BOM.
        $json = $wt | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText($WtSettings, $json, (New-Object System.Text.UTF8Encoding $false))
        Write-Ok 'settings.json written (UTF-8, no BOM)'    } catch {
        Write-Fail "could not patch settings.json: $($_.Exception.Message)"
        Write-Info "set it manually: profiles.defaults.fontFace = '$NerdFontFamily'"
    }
}

# ---------------------------------------------------------------------------
# 5. PowerShell profile files
# ---------------------------------------------------------------------------
Write-Step 'PowerShell profile files'

if (-not (Test-Path $ProfileSrc)) {
    Write-Fail "profile source not found: $ProfileSrc"
} else {
    New-Item -ItemType Directory -Force -Path $SharedDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path $WinPsBoot) | Out-Null

    Copy-Item $ProfileSrc $SharedFile -Force
    Write-Ok "shared profile  -> $SharedFile"

    # --- prompt theme ---
$themeSrc = Join-Path $ScriptRoot 'themes\powercli.omp.json'
    if (Test-Path $themeSrc) {
        New-Item -ItemType Directory -Force -Path $ThemeDir | Out-Null
        Copy-Item $themeSrc (Join-Path $ThemeDir 'powercli.omp.json') -Force
        Write-Ok "prompt theme   -> $(Join-Path $ThemeDir 'powercli.omp.json')"
    } else {
        Write-Warn2 "theme file not found: $themeSrc"
    }

    $bootstrap = @"
# ==============================================================================
#  $((Split-Path $WinPsBoot -Leaf)) :: Profile bootstrap
#  The real implementation lives in:
#    $(Join-Path $SharedDir 'PowerCLI.ps1')
#  Edit THAT file - this file only loads it.
# ==============================================================================

`$shared = '$SharedFile'

if (Test-Path `$shared) {
    try {
        . `$shared
    } catch {
        Write-Warning "PowerCLI profile failed to load: `$_"
    }
} else {
    Write-Warning "PowerCLI profile not found at: `$shared"
}
"@
    # UTF-8 *with* BOM so Windows PowerShell 5.1 detects the encoding correctly.
    $utf8Bom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($PwshBoot,  $bootstrap, $utf8Bom)
    [System.IO.File]::WriteAllText($WinPsBoot, $bootstrap, $utf8Bom)
    Write-Ok "PS 7 bootstrap  -> $PwshBoot"
    Write-Ok "PS 5.1 bootstrap-> $WinPsBoot"
}

# ---------------------------------------------------------------------------
# 6. Verify
# ---------------------------------------------------------------------------
Write-Step 'Verification'

$checks = @(
    @{ Name = 'Git';              Test = { [bool](Get-Command git -ErrorAction Ignore) } }
    @{ Name = 'PowerShell 7';     Test = { [bool](Get-Command pwsh -ErrorAction Ignore) } }
    @{ Name = 'Oh-My-Posh';       Test = { [bool](Get-Command oh-my-posh -ErrorAction Ignore) } }
    @{ Name = 'PSReadLine';       Test = { [bool](Get-Module -ListAvailable PSReadLine) } }
    @{ Name = 'Nerd Font';        Test = { (Get-ItemProperty -Path $FontRegKey -ErrorAction Ignore | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -like "$NerdFontFamily *" }) -ne $null } }
    @{ Name = 'Profile (PS 7)';   Test = { Test-Path $PwshBoot } }
    @{ Name = 'Profile (PS 5.1)'; Test = { Test-Path $WinPsBoot } }
    @{ Name = 'Shared profile';   Test = { Test-Path $SharedFile } }
)

$failed = 0
foreach ($c in $checks) {
    $ok = $false
    try { $ok = & $c.Test } catch { $ok = $false }
    if ($ok) { Write-Ok $c.Name } else { Write-Warn2 "$($c.Name) not detected"; $failed++ }
}

Write-Host ''
Write-Host '  ================================================' -ForegroundColor Cyan
if ($failed -eq 0) {
    Write-Host '   Installation complete.' -ForegroundColor Green
} else {
    Write-Host "   Installation complete ($failed item(s) need attention)." -ForegroundColor Yellow
}
Write-Host '  ================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host '   NEXT STEPS' -ForegroundColor Cyan
Write-Host '    1. Close and reopen Windows Terminal (needed for the font).'
Write-Host '    2. Type  status   to check the environment'
Write-Host '    3. Type  psclihelp  to see every command'
Write-Host ''
