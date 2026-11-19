# ==============================================================================
#  PowerCLI :: Professional PowerShell Profile
#  Shared by Windows PowerShell 5.1 and PowerShell 7+
#  --------------------------------------------------------------------------
#  Loaded via:  Microsoft.PowerShell_profile.ps1  ->  . $PROFILE\PowerCLI.ps1
#  Edit this file to customise. Re-load at any time with:  reload-profile
# ==============================================================================

$ErrorActionPreference = 'Continue'

# Suppress the 'PowerShell 7.7.0' startup banner when running outside
# Windows Terminal (which already uses -NoLogo). Only on the first load so
# that reload-profile does not wipe the screen.
if (-not $global:PowerCLILoaded) {
    try {
        if (-not [Console]::IsOutputRedirected) {
            Clear-Host
        }
    } catch { }
    $global:PowerCLILoaded = $true
}

# ==============================================================================
#  SECTION 0 :: Environment detection & shared configuration
# ==============================================================================

# Determine the correct profile directory (handles OneDrive redirection).
$profileDir = Split-Path $PROFILE
$documentsDir = Split-Path $profileDir

$global:PowerCLI = [ordered]@{
    LogDir         = (Join-Path $env:TEMP 'PowerCLI\logs')
    RunDir         = (Join-Path $env:TEMP 'PowerCLI\run')
    Theme          = 'jandedobbeleer'
    ThemePath      = (Join-Path $documentsDir 'PowerShell\themes\powercli.omp.json')
    PlainThemePath = (Join-Path $documentsDir 'PowerShell\themes\powercli-plain.omp.json')
    ProfilePath    = $PSCommandPath
}

$global:PowerCLIBoxed     = ([char]0x2502)  # |
$global:PowerCLICheck     = ([char]0x2714)  # v
$global:PowerCLICross     = ([char]0x2718)  # x
$global:PowerCLIBullet    = ([char]0x2022)  # *
$global:PowerCLIArrow     = ([char]0x2192)  # ->
$global:PowerCLISeparator = ([char]0x2500)  # -

$global:PowerCLILine  = ($global:PowerCLISeparator.ToString() * 76)
$global:PowerCLILine2 = ($global:PowerCLISeparator.ToString() * 50)

foreach ($d in @($global:PowerCLI.LogDir, $global:PowerCLI.RunDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

# ==============================================================================
#  SECTION 1 :: PSReadLine  (history, key bindings, autocompletion)
# ==============================================================================

try {
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Import-Module PSReadLine -ErrorAction Stop

        $psrl = Get-Module PSReadLine
        $hasPrediction = ([version]$psrl.Version -ge [version]'2.2.0')

        Set-PSReadLineOption -EditMode Windows -ErrorAction Ignore
        Set-PSReadLineOption -MaximumHistoryCount 20000 -ErrorAction Ignore
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd -ErrorAction Ignore
        Set-PSReadLineOption -BellStyle None -ErrorAction Ignore
        Set-PSReadLineOption -ShowToolTips -ErrorAction Ignore

        $canPredict = $hasPrediction -and -not [Console]::IsOutputRedirected
        if ($canPredict) {
            try { Set-PSReadLineOption -PredictionSource History -ErrorAction Stop }
            catch { try { Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction Stop } catch { } }
            try { Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop } catch { }
        }

        $bind = {
            param([string]$Key, [string]$Fn)
            try { Set-PSReadLineKeyHandler -Key $Key -Function $Fn -ErrorAction Stop }
            catch { Write-Verbose "Key binding '$Key' -> '$Fn' skipped: $($_.Exception.Message)" }
        }
        & $bind 'Tab'             'MenuComplete'
        & $bind 'UpArrow'         'HistorySearchBackward'
        & $bind 'DownArrow'       'HistorySearchForward'
        & $bind 'Ctrl+UpArrow'    'HistorySearchBackward'
        & $bind 'Ctrl+DownArrow'  'HistorySearchForward'
        & $bind 'Ctrl+LeftArrow'  'BackwardWord'
        & $bind 'Ctrl+RightArrow' 'ForwardWord'
        & $bind 'Alt+LeftArrow'   'PreviousHistory'
        & $bind 'Alt+RightArrow'  'NextHistory'
        & $bind 'Ctrl+d'          'DeleteCharOrExit'
        & $bind 'Ctrl+k'          'KillLine'
        & $bind 'Ctrl+c'          'CopyOrCancelLine'
        & $bind 'Ctrl+r'          'ReverseSearchHistory'
        & $bind 'Ctrl+f'          'ForwardChar'
        & $bind 'Ctrl+b'          'BackwardChar'
    }
} catch {
    Write-Verbose "PSReadLine setup skipped: $_"
}

# ==============================================================================
#  SECTION 2 :: Prompt  (Oh-My-Posh with a clean native fallback)
# ==============================================================================

function Get-PowerCLIGitInfo {
    if (-not (Get-Command git -ErrorAction Ignore)) { return $null }
    try {
        $branch = (Get-GitOutput 'rev-parse --abbrev-ref HEAD' | Select-Object -First 1)
        if (-not $branch) { return $null }
        $dirty = (Get-GitOutput 'status --porcelain')
        $ahead = 0; $behind = 0
        $track = (Get-GitOutput 'rev-list --left-right --count "@{upstream}...HEAD"' | Select-Object -First 1)
        if ($track) {
            $parts = $track -split '\s+'
            if ($parts.Count -ge 2) { $behind = [int]$parts[0]; $ahead = [int]$parts[1] }
        }
        return [pscustomobject]@{
            Branch = $branch
            Dirty  = [bool]$dirty
            Ahead  = $ahead
            Behind = $behind
        }
    } catch { return $null }
}

function global:Get-GitOutput {
    param(
        [Parameter(Mandatory, Position = 0)][string]$GitArgs,
        [string]$Directory
    )
    if (-not (Get-Command git -ErrorAction Ignore)) { return @() }
    $prefix = ''
    if ($Directory) { $prefix = '-C "' + $Directory + '" ' }
    if ($env:OS -eq 'Windows_NT') {
        return @(& cmd /c "git $prefix$GitArgs 2>nul")
    }
    return @(& git $prefix.Trim().Split(' ') $GitArgs.Split(' ') 2>&1 |
             Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] })
}

# ---------------------------------------------------------------------------
#  Nerd Font detection
#  The prompt icons (, , ,  ...) live in the Nerd Font's private-use
#  area. If the active terminal font does not include them, every icon shows
#  up as an empty box (tofu). Detect support cheaply (no Add-Type - that costs
#  ~470ms) and fall back to a glyph-free theme when the font is not usable.
# ---------------------------------------------------------------------------

function global:Test-PowerCLINerdFont {
    # Explicit overrides always win.
    if ($env:POWERCLI_PLAIN -eq '1')       { return $false }
    if ($env:POWERCLI_FORCE_GLYPHS -eq '1') { return $true }

    $isNerd = { param($Name) [bool]($Name -and ($Name -match '\bNF\b|\bNFM\b|Nerd Font|Nerd')) }

    # 1) Windows Terminal knows exactly which font it renders with.
    if ($env:WT_SESSION) {
        $wt = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
        if (Test-Path $wt) {
            try {
                $ff = (Get-Content $wt -Raw -ErrorAction Stop | ConvertFrom-Json).profiles.defaults.fontFace
                if ($ff) { return (& $isNerd $ff) }   # authoritative for WT
            } catch { }
        }
    }

    # 2) Any other terminal: assume a Nerd Font the user deliberately installed
    #    is also the font they chose to use; if none is installed, glyphs are
    #    guaranteed to be boxes.
    $nrd = $false
    foreach ($key in @(
        'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts',
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    )) {
        try {
            $hit = (Get-ItemProperty -Path $key -ErrorAction Stop).PSObject.Properties |
                   Where-Object { (& $isNerd $_.Name) } |
                   Select-Object -First 1
            if ($hit) { $nrd = $true; break }
        } catch { }
    }
    return $nrd
}

$global:PowerCLINerdFont = Test-PowerCLINerdFont

$global:PowerCLIUseOmp = $false
try {
    if ($env:POWERCLI_NO_OMP -ne '1' -and (Get-Command oh-my-posh -ErrorAction Ignore)) {
        # Pick the glyph theme only when the terminal can actually render it.
        $themeConfig = if ($global:PowerCLINerdFont -and (Test-Path $global:PowerCLI.ThemePath)) {
                        $global:PowerCLI.ThemePath
                    } elseif (-not $global:PowerCLINerdFont -and (Test-Path $global:PowerCLI.PlainThemePath)) {
                        $global:PowerCLI.PlainThemePath
                    } elseif (Test-Path $global:PowerCLI.ThemePath) {
                        $global:PowerCLI.ThemePath
                    } else { $global:PowerCLI.Theme }
        $initScript = (& oh-my-posh init pwsh --config $themeConfig 2>$null | Out-String)
        if ($initScript -and $initScript.Trim().Length -gt 0) {
            Invoke-Expression $initScript
            $global:PowerCLIUseOmp = $true
        }
    }
} catch {
    Write-Verbose "Oh-My-Posh setup skipped: $_"
}

# Capture Oh-My-Posh's prompt script block before replacing it.
$global:PowerCLIOmpPromptBlock = $null
if ($global:PowerCLIUseOmp) {
    $ompPromptCmd = Get-Command prompt -ErrorAction Ignore
    if ($ompPromptCmd -and $ompPromptCmd.CommandType -eq 'Function') {
        $global:PowerCLIOmpPromptBlock = $ompPromptCmd.ScriptBlock
    }
}

$global:PowerCLIClock = ($env:POWERCLI_NO_CLOCK -ne '1')
$global:PowerCLIWidthChanged = $false
$global:PowerCLILastPromptWidth = $null

function global:Get-PowerCLIVisibleWidth {
    param([string]$Text)
    if (-not $Text) { return 0 }
    $plain = [regex]::Replace($Text, '\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)', '')  # OSC
    $plain = [regex]::Replace($plain, '\x1b\[[0-9;:?]*[ -\/]*[@-~]', '')      # CSI
    return $plain.Length
}

function global:Get-PowerCLITerminalWidth {
    try {
        $w = $Host.UI.RawUI.WindowSize.Width
        if ($w -gt 20) { return $w }
    } catch { }
    return 120
}

if ($global:PowerCLIUseOmp -and $global:PowerCLIOmpPromptBlock -and $global:PowerCLIClock) {
    function global:prompt {
        $left = (& $global:PowerCLIOmpPromptBlock) -join "`n"
        if (-not $left) { return $left }

        $e     = [char]27
        # The clock glyph is Nerd-Font-only; use a plain character otherwise.
        $clockIcon = if ($global:PowerCLINerdFont) { "$([char]0xF017)" } else { '' }
        $clock = "$($e)[38;2;124;140;165m $clockIcon $(Get-Date -Format 'HH:mm:ss')$($e)[0m"
        $cw    = Get-PowerCLIVisibleWidth $clock
        $lw    = Get-PowerCLIVisibleWidth $left
        $tw    = Get-PowerCLITerminalWidth

        if (($tw - $lw - $cw) -lt 2) {
            $global:PowerCLILastPromptWidth = $tw
            return $left
        }

        $clear = ''
        if ($global:PowerCLIWidthChanged) {
            $clear = "$($e)[1B$($e)[2K$($e)[1A"
            $global:PowerCLIWidthChanged = $false
        }
        $global:PowerCLILastPromptWidth = $tw

        "$clear$left$($e)[$($tw - $cw + 1)`G$clock$($e)[$($lw + 1)`G"
    }
}

if (-not $global:PowerCLIUseOmp) {
    # Native fallback prompt - two-line, colourised, git aware.
    # Uses the same Nord palette as the Oh-My-Posh theme.
    function global:prompt {
        $e = [char]27
        $cReset = "$($e)[0m"; $cRed    = "$($e)[91m"; $cGreen  = "$($e)[92m"
        $cYellow = "$($e)[93m"; $cCyan   = "$($e)[96m"; $cGray   = "$($e)[90m"
        $cMauve  = "$($e)[95m"; $cIce    = "$($e)[96m"

        $cwd  = $ExecutionContext.SessionState.Path.CurrentLocation.Path
        $disp = $cwd
        if ($disp.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) {
            $disp = '~' + $disp.Substring($HOME.Length)
        }

        $admin = ''
        if (Test-Path Variable:\__PowerCLIAdmin) { $admin = " $cRed[ADMIN]$cReset" }

        $git = Get-PowerCLIGitInfo
        $gitTxt = ''
        if ($git) {
            $mark = ''
            if ($git.Dirty)        { $mark  = " $cYellow*$cReset" }
            if ($git.Ahead  -gt 0) { $mark += " $cGreen+$($git.Ahead)$cReset" }
            if ($git.Behind -gt 0) { $mark += " $cRed-$($git.Behind)$cReset" }
            $gitTxt = "$cMauve$($git.Branch)$cReset$mark"
        }

        "$cGray$($PSVersionTable.PSVersion)$cReset$admin  $gitTxt`n$cIce$disp$cReset`n$cGray>$cReset "
    }
}

# ---------------------------------------------------------------------------
#  Keep the clock anchored when the terminal is resized
# ---------------------------------------------------------------------------

function global:Sync-PowerCLIPromptWidth {
    try {
        $w = Get-PowerCLITerminalWidth
        if (-not $w -or $w -eq $global:PowerCLILastWidth) { return }

        $line = $null
        $state = 0
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$state) | Out-Null

        $e = [char]27
        Write-Host -NoNewline "$($e)[1B$($e)[2K$($e)[1A"

        $global:PowerCLILastWidth = $w
        $global:PowerCLIWidthChanged = $true
        if (Get-Command Invoke-PoshPromptRepaint -ErrorAction Ignore) {
            Invoke-PoshPromptRepaint
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        }
    } catch {
        # Never let the watcher break the session.
    }
}

$global:PowerCLILastWidth = Get-PowerCLITerminalWidth
if (-not ($global:PowerCLITimer -and $global:PowerCLITimer.Enabled)) {
    try {
        $timer = New-Object System.Timers.Timer
        $timer.Interval = 500
        $null = Register-ObjectEvent -InputObject $timer -EventName 'Elapsed' -Action {
            Sync-PowerCLIPromptWidth
        }
        $timer.Start()
        $global:PowerCLITimer = $timer
    } catch {
        Write-Verbose "Clock resize watcher not started: $_"
    }
}

# ==============================================================================
#  SECTION 3 :: Environment variables & console encoding
# ==============================================================================

try {
    if (-not [Console]::IsOutputRedirected) {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    }
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    Write-Verbose "Console encoding could not be set to UTF-8: $_"
}

if (-not $env:DOTNET_CLI_TELEMETRY_OPTOUT)          { $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1' }
if (-not $env:DOTNET_NOLOGO)                          { $env:DOTNET_NOLOGO = '1' }
if (-not $env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE)      { $env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1' }

$env:PATH = (@(
    'C:\Program Files\Git\cmd'
    'C:\Program Files\Git\bin'
    'C:\Program Files\dotnet'
    "$env:LOCALAPPDATA\Programs\Git\cmd"
    "$env:LOCALAPPDATA\Programs\oh-my-posh\bin"
    $env:PATH
) | Where-Object { $_ } | Select-Object -Unique) -join ';'

# ==============================================================================
#  SECTION 4 :: Core aliases
# ==============================================================================

Set-Alias -Name ll    -Value Get-ChildItem -Option AllScope -Force
Set-Alias -Name la    -Value Get-ChildItem -Option AllScope -Force
Set-Alias -Name which -Value Get-Command    -Option AllScope -Force

function global:..  { Set-Location -Path '..' }
function global:... { Set-Location -Path '..\..' }

# ==============================================================================
#  SECTION 5 :: General helper functions
# ==============================================================================

function global:mkcd {
    param([Parameter(Mandatory, Position = 0)][string]$Path)
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null }
    Set-Location -Path $Path
    Write-Host "$global:PowerCLIBoxed $($ExecutionContext.SessionState.Path.CurrentLocation.Path)" -ForegroundColor DarkCyan
}

function global:touch {
    param([Parameter(Mandatory, Position = 0)][string]$Path)
    if (Test-Path $Path) { (Get-Item $Path).LastWriteTime = Get-Date }
    else { New-Item -ItemType File -Force -Path $Path | Out-Null }
}

function global:ff {
    param(
        [Parameter(Mandatory, Position = 0)][string]$Name,
        [Parameter(Position = 1)][string]$Path = '.',
        [switch]$Shallow
    )
    Get-ChildItem -Path $Path -Filter $Name -Recurse:(-not $Shallow) -Force -ErrorAction Ignore
}

function global:grep {
    param(
        [Parameter(Mandatory, Position = 0)][string]$Pattern,
        [Parameter(Position = 1)][string]$Path = '.',
        [string]$Include,
        [switch]$CaseSensitive
    )
    $fileParams = @{ Path = $Path; Recurse = $true; File = $true; ErrorAction = 'Ignore' }
    if ($Include) { $fileParams['Include'] = $Include }
    Get-ChildItem @fileParams | Select-String -Pattern $Pattern -CaseSensitive:$CaseSensitive -ErrorAction Ignore
}

function global:json {
    param([Parameter(Mandatory, Position = 0)][string]$Path)
    Get-Content -Path $Path -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 12
}

function global:ports {
    param([string]$Port = '')
    $conns = Get-NetTCPConnection -State Listen -ErrorAction Ignore
    if ($Port) { $conns = $conns | Where-Object { $_.LocalPort -eq [int]$Port } }
    $conns |
        Select-Object LocalAddress, LocalPort,
            @{n='Process';e={ (Get-Process -Id $_.OwningProcess -ErrorAction Ignore).ProcessName }} |
        Sort-Object LocalPort | Format-Table -AutoSize
}

function global:killport {
    param([Parameter(Mandatory, Position = 0)][int]$Port)
    $procIds = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Ignore |
               Select-Object -ExpandProperty OwningProcess -Unique
    if (-not $procIds) { Write-Host "Nothing listening on port $Port" -ForegroundColor DarkGray; return }
    foreach ($procId in $procIds) {
        $p = Get-Process -Id $procId -ErrorAction Ignore
        if ($p) {
            Write-Host "Killing $($p.ProcessName) (PID $procId) on port $Port" -ForegroundColor Yellow
            Stop-Process -Id $procId -Force -ErrorAction Ignore
        }
    }
}

function global:ipinfo {
    try { Write-Host "Public : " -NoNewline; Write-Host (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 5) }
    catch { Write-Host "Public : (offline)" }
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Ignore |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
        Select-Object InterfaceAlias, IPAddress, PrefixLength | Format-Table -AutoSize
}

function global:now { Get-Date -Format 'yyyy-MM-dd HH:mm:ss' }
function global:utc  { (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss') }

function global:history-search {
    param([Parameter(Mandatory, Position = 0)][string]$Term)
    Get-History | Where-Object { $_.CommandLine -like "*$Term*" } |
        Select-Object -Last 20 | Format-Table Id, CommandLine -AutoSize -Wrap
}

function global:reload-profile {
    if ($global:PowerCLI.ProfilePath -and (Test-Path $global:PowerCLI.ProfilePath)) {
        . $global:PowerCLI.ProfilePath
        Write-Host "$global:PowerCLICheck Profile reloaded" -ForegroundColor Green
    } else {
        Write-Host 'Profile path not found' -ForegroundColor Red
    }
}

# ==============================================================================
#  SECTION 6 :: Git helpers
# ==============================================================================

if (Get-Command git -ErrorAction Ignore) {
    function global:git-status   { git status -sb }
    function global:git-branch   { git branch -v }
    function global:git-log      { git log --oneline --graph --decorate --all -n 30 }
    function global:git-diff     { git diff }
    function global:git-staged   { git diff --staged }
    function global:git-add      { param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Paths) git add -- @Paths }
    function global:git-commit   { param([Parameter(Mandatory, Position = 0)][string]$Message) git commit -m $Message }
    function global:git-add-commit {
        param([Parameter(Mandatory, Position = 0)][string]$Message)
        git add --all
        git commit -m $Message
    }
    function global:git-pull     { git pull --rebase --autostash }
    function global:git-push     { git push }
    function global:git-checkout { param([Parameter(Mandatory, Position = 0)][string]$Branch) git checkout $Branch }
    function global:git-stash    { param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest) git stash -- @Rest }
    function global:git-root     {
        $r = (Get-GitOutput 'rev-parse --show-toplevel' | Select-Object -First 1)
        if ($r) { Set-Location $r } else { Write-Host 'Not a git repository' -ForegroundColor Red }
    }
    function global:git-undo     { git reset --soft HEAD~1 }
    function global:git-root-set { param([Parameter(Mandatory, Position = 0)][string]$Name) git checkout -b $Name }

    # NOTE: names deliberately avoid PowerShell built-in aliases
    # (gl = Get-Location, gc = Get-Content, gp = Get-ItemProperty).
    Set-Alias -Name gs     -Value git-status   -Option AllScope -Force
    Set-Alias -Name gb     -Value git-branch   -Option AllScope -Force
    Set-Alias -Name glog   -Value git-log      -Option AllScope -Force
    Set-Alias -Name gd     -Value git-diff     -Option AllScope -Force
    Set-Alias -Name gadd   -Value git-add      -Option AllScope -Force
    Set-Alias -Name gcommit -Value git-commit   -Option AllScope -Force
    Set-Alias -Name gac    -Value git-add-commit -Option AllScope -Force
    Set-Alias -Name gpull  -Value git-pull     -Option AllScope -Force
    Set-Alias -Name gpush  -Value git-push     -Option AllScope -Force
    Set-Alias -Name gco    -Value git-checkout -Option AllScope -Force
    Set-Alias -Name groot  -Value git-root     -Option AllScope -Force
    Set-Alias -Name gnew   -Value git-root-set -Option AllScope -Force
    Set-Alias -Name gst    -Value git-stash    -Option AllScope -Force
} else {
    Write-Warning "Git not found - git helpers disabled. Install with: winget install Git.Git"
}

# ==============================================================================
#  SECTION 7 :: .NET / dotnet helpers
# ==============================================================================

if (Get-Command dotnet -ErrorAction Ignore) {
    function global:build     { param([string]$Proj = '.', [string]$Cfg = 'Debug') dotnet build $Proj -c $Cfg }
    function global:run       { param([string]$Proj = '.') dotnet run --project $Proj }
    function global:watch     { param([string]$Proj = '.') dotnet watch --project $Proj }
    function global:test      { param([string]$Proj = '.') dotnet test $Proj }
    function global:restore   { param([string]$Proj = '.') dotnet restore $Proj }
    function global:publish   { param([string]$Proj = '.', [string]$Out = './publish') dotnet publish $Proj -c Release -o $Out }
    function global:clean     { param([string]$Proj = '.') dotnet clean $Proj }
    function global:packlist  { param([string]$Proj = '.') dotnet list $Proj package --include-transitive }
    function global:outdated  { param([string]$Proj = '.') dotnet list $Proj package --outdated }
    function global:dotnetinfo {
        Write-Host "SDK      : " -NoNewline; dotnet --version
        Write-Host "Runtimes :"
        dotnet --list-runtimes | ForEach-Object { Write-Host "   $_" }
    }
    Set-Alias -Name b  -Value build   -Option AllScope -Force
    Set-Alias -Name br -Value run     -Option AllScope -Force
    Set-Alias -Name t  -Value test    -Option AllScope -Force
    Set-Alias -Name rw -Value restore -Option AllScope -Force
}

# ==============================================================================
#  SECTION 8 :: Docker helpers
# ==============================================================================

if (Get-Command docker -ErrorAction Ignore) {
    function global:dps { docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" }
    function global:dpa { docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" }
    function global:dc  { param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest) docker compose @Rest }
    function global:docker-clean {
        docker system prune -af --volumes
    }
    function global:docker-stop-all {
        $ids = docker ps -q 2>$null
        if ($ids) { docker stop $ids } else { Write-Host 'No running containers' -ForegroundColor DarkGray }
    }
    Set-Alias -Name dp -Value dps -Option AllScope -Force
}

# ==============================================================================
#  SECTION 9 :: General helpers & command reference
# ==============================================================================

# --- Database helpers (only if sqlcmd is installed) --------------------------
if (Get-Command sqlcmd -ErrorAction Ignore) {
    function global:db-list {
        param([string]$Server = 'localhost,1433', [string]$User = 'sa', [string]$Password = 'Your_password123')
        sqlcmd -S $Server -U $User -P $Password -C -Q "SELECT name FROM sys.databases;" -W -s"|"
    }
    function global:db-query {
        param(
            [Parameter(Mandatory, Position = 0)][string]$Query,
            [string]$Server = 'localhost,1433',
            [string]$User = 'sa',
            [string]$Password = 'Your_password123'
        )
        sqlcmd -S $Server -U $User -P $Password -C -Q $Query -W -s"|"
    }
}

function global:status {
    Write-Host ''
    Write-Host '  PowerCLI - environment status' -ForegroundColor Cyan
    Write-Host "  $global:PowerCLILine2" -ForegroundColor DarkCyan
    $gitState  = if (Get-Command git -ErrorAction Ignore) { (Get-GitOutput 'rev-parse --abbrev-ref HEAD' | Select-Object -First 1) } else { 'not installed' }
    $dkState   = if (Get-Command docker -ErrorAction Ignore) { (docker --version) } else { 'not installed' }
    $dnState   = if (Get-Command dotnet -ErrorAction Ignore) { (dotnet --version) } else { 'not installed' }
    $pwshState = $PSVersionTable.PSVersion.ToString()
    Write-Host "  $global:PowerCLIBoxed Root        : $PWD" -ForegroundColor DarkGray
    Write-Host "  $global:PowerCLIBoxed Git         : $gitState" -ForegroundColor DarkGray
    Write-Host "  $global:PowerCLIBoxed Docker      : $dkState" -ForegroundColor DarkGray
    Write-Host "  $global:PowerCLIBoxed .NET SDK    : $dnState" -ForegroundColor DarkGray
    Write-Host "  $global:PowerCLIBoxed PowerShell  : $pwshState" -ForegroundColor DarkGray
    Write-Host "  $global:PowerCLIBoxed Prompt      : $(if ($global:PowerCLIUseOmp) { 'Oh-My-Posh (' + (Split-Path $global:PowerCLI.ThemePath -Leaf) + ')' } else { 'native fallback' })" -ForegroundColor DarkGray
    Write-Host "  $global:PowerCLIBoxed Log dir     : $global:PowerCLI.LogDir" -ForegroundColor DarkGray
    Write-Host ''
}

function global:psclihelp {
    Write-Host ''
    Write-Host '  PowerCLI - command reference' -ForegroundColor Cyan
    Write-Host "  $global:PowerCLILine" -ForegroundColor DarkCyan
    Write-Host '  NAVIGATION' -ForegroundColor Yellow
    Write-Host '    mkcd <path>        create a directory and enter it'
    Write-Host '    ..  /  ...         up one / two levels'
    Write-Host '    psclihelp          show this help'
    Write-Host '    status             environment summary'
    Write-Host ''
    Write-Host '  GIT' -ForegroundColor Yellow
    Write-Host '    gs                git status -sb'
    Write-Host '    gb                git branch -v'
    Write-Host '    glog              git log --oneline --graph --decorate'
    Write-Host '    gd / gadd         git diff / git add'
    Write-Host '    gcommit <msg>     git commit -m'
    Write-Host '    gac <msg>         git add --all + git commit -m in one command'
    Write-Host '    gpull / gpush     git pull --rebase / git push'
    Write-Host '    gco <branch>      git checkout'
    Write-Host '    gnew <branch>     create and switch to a new branch'
    Write-Host '    groot             jump to the repository root'
    Write-Host '    gst               git stash'
    Write-Host ''
    Write-Host '  BUILD / TEST (.NET)' -ForegroundColor Yellow
    Write-Host '    build [proj]      dotnet build'
    Write-Host '    run   [proj]      dotnet run'
    Write-Host '    watch [proj]      dotnet watch'
    Write-Host '    test  [proj]      dotnet test'
    Write-Host '    restore [proj]    dotnet restore'
    Write-Host '    publish [proj]    dotnet publish'
    Write-Host '    clean [proj]      dotnet clean'
    Write-Host '    b / br / t / rw   build / run / test / restore'
    Write-Host ''
    Write-Host '  DOCKER' -ForegroundColor Yellow
    Write-Host '    dps               docker ps'
    Write-Host '    dpa               docker ps -a'
    Write-Host '    dc <args>         docker compose <args>'
    Write-Host '    docker-clean      prune everything'
    Write-Host '    docker-stop-all   stop all containers'
    Write-Host '    dp                alias for dps'
    Write-Host ''
    Write-Host '  DATABASE / SQL' -ForegroundColor Yellow
    Write-Host '    db-query <sql>    run a SQL query (localhost,1433)'
    Write-Host '    db-list           list databases'
    Write-Host ''
    Write-Host '  GENERAL' -ForegroundColor Yellow
    Write-Host '    mkcd <path>       create a directory and enter it'
    Write-Host '    ff <name>         find files by name (recursive)'
    Write-Host '    grep <pattern>    search file contents'
    Write-Host '    json <file>       pretty-print JSON'
    Write-Host '    ports [port]      show listening ports'
    Write-Host '    killport <port>   kill the process on a port'
    Write-Host '    ipinfo            local + public IP'
    Write-Host '    now / utc         timestamps'
    Write-Host '    history-search    search command history'
    Write-Host '    reload-profile     re-apply the profile'
    Write-Host ''
}

# ==============================================================================
#  SECTION 10 :: Startup note
# ==============================================================================
# PowerShell prints 'Loading personal and system profiles took Xms' after the
# profile finishes, but only when the combined load time exceeds 500 ms - a
# hard-coded threshold with no environment variable to disable it.
#
# There is no way to suppress it from inside the profile: the message is
# written by the host *after* this file has finished running. The only
# supported switch is -NoLogo on the command line, which the installer now
# adds to every PowerShell entry in Windows Terminal (both 5.1 and 7+).
#
# An earlier version of this section spawned a background runspace that slept
# for a second and called Clear-Host to wipe the message. It never worked:
# a background runspace has no interactive host, so Clear-Host always threw
# 'does not support user interaction' and the catch swallowed it - while
# still paying for a runspace on every start.
#
# Outside Windows Terminal (Win+R -> pwsh) there is no -NoLogo, so a slow
# machine can still show the message. Speed is the only lever there; see
# DESIGN.md for where the load time goes.
