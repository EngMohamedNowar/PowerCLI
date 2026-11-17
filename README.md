# CarRentalApp CLI — Master Document

Everything about the professional PowerShell environment built for this repo:
what it is, what changed on the machine, why each decision was made, and how
to recreate it anywhere.

> **Related documents**
> - [`README-CLI.md`](README-CLI.md) — command reference (what to type)
> - [`SETUP-CLI.md`](SETUP-CLI.md) — step-by-step reproduction guide
> - [`tools/powershell/`](tools/powershell/) — the actual source

---

## 1. TL;DR

```powershell
# On any new Windows machine
git clone https://github.com/EngMohamedNowar/C4_CarRentalApp.git
cd C4_CarRentalApp
.\tools\powershell\Install-CLI.ps1
```

Open Windows Terminal. That's it.

```powershell
status      # environment summary
crrhelp     # every command
```

---

## 2. The system at a glance

```
┌──────────────────────────────────────────────────────────────────────┐
│  Windows Terminal  ·  PowerShell 7.7  ·  CaskaydiaCove NF font      │
│  background #1C1C1C   foreground #D8DEE9   cursor #88C0D0            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   user │ 📁 C4_CarRentalApp │ ⎇ master ↑1 ✎ ?1 │ ✔      🕐 13:08:30 │
│    ↑                          ↑                ↑        ↑            │
│    └──────── left side ───────┴────────────────┘        │            │
│                                                     right edge        │
│                                            (cursor stays on the left) │
├──────────────────────────────────────────────────────────────────────┤
│  PSReadLine 2.4.5   history 20 000 · autocomplete · key bindings   │
│  Oh-My-Posh 32.1.0  custom Nord theme (tools/powershell/themes/)     │
├──────────────────────────────────────────────────────────────────────┤
│  CarRentalProfile.ps1  (792 lines, 11 sections)                      │
│    41 functions · 21 aliases · 0 errors on load                     │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. What changed on the machine

### Installed

| Tool | Version | How | Was it there? |
|---|---|---|---|
| **Git** | 2.56.0 | `winget install Git.Git` | ❌ was missing entirely |
| **PowerShell 7** | 7.7.0 | `winget install Microsoft.PowerShell` | ❌ only 5.1 was present |
| **CaskaydiaCove NF** | 3.5.1 | nerdfonts GitHub release → `HKCU` | ❌ missing (prompt icons were boxes) |
| Oh-My-Posh | 32.1.0 | pre-installed | ✅ |
| PSReadLine | 2.0.0 / 2.4.5 | ships with Windows / PS 7 | ✅ |
| .NET SDK | 10.0.401 | pre-installed | ✅ |
| Docker Desktop | 29.8.0 | pre-installed | ✅ (daemon must be running) |
| SQL Server Client | 170 | pre-installed | ✅ |

The Nerd Font is registered **per user** (`HKCU`) — no admin rights needed, and
it survives a Windows Terminal uninstall.

### Files created

| Path | Role |
|---|---|
| `tools/powershell/CarRentalProfile.ps1` | **the CLI** — 792 lines, source of truth |
| `tools/powershell/Install-CLI.ps1` | idempotent installer, 369 lines |
| `tools/powershell/themes/carrental.omp.json` | custom Oh-My-Posh theme, 70 lines |
| `%USERPROFILE%\Documents\PowerShell\CarRentalProfile.ps1` | copy of the profile (the real one) |
| `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` | bootstrap for PS 7 |
| `%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` | bootstrap for PS 5.1 |
| `%USERPROFILE%\Documents\PowerShell\themes\carrental.omp.json` | copy of the theme |
| `%LOCALAPPDATA%\Microsoft\Windows\Fonts\CaskaydiaCoveNerdFont-*.ttf` | 6 font files |

Both bootstrap files are one-line loaders — the implementation lives in exactly
one place.

### Windows Terminal — `settings.json`

```json
{
  "defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
  "profiles": {
    "defaults": {
      "fontFace": "CaskaydiaCove NF",
      "background": "#1C1C1C",
      "foreground": "#D8DEE9",
      "cursorColor": "#88C0D0",
      "selectionBackground": "#3B4252"
    }
  }
}
```

- Default profile switched from Windows PowerShell 5.1 → **PowerShell 7**.
- Pure black on pure white is the harshest combination for long sessions; the
  soft charcoal + off-white pair measurably reduces halation.
- **The file must stay UTF-8 *without* a BOM** — Windows Terminal refuses to
  parse a BOM'd JSON file. The installer writes it with `UTF8Encoding($false)`.

### Registry — `HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts`

```
CaskaydiaCove NF Regular (TrueType)      -> ...\CaskaydiaCoveNerdFont-Regular.ttf
CaskaydiaCove NF Bold (TrueType)         -> ...\CaskaydiaCoveNerdFont-Bold.ttf
CaskaydiaCove NF Italic (TrueType)       -> ...\CaskaydiaCoveNerdFont-Italic.ttf
CaskaydiaCove NF Bold Italic (TrueType)  -> ...\CaskaydiaCoveNerdFont-BoldItalic.ttf
CaskaydiaCove NFM Regular (TrueType)     -> ...\CaskaydiaCoveNerdFontMono-Regular.ttf
CaskaydiaCove NFM Bold (TrueType)        -> ...\CaskaydiaCoveNerdFontMono-Bold.ttf
```

### Repository cleanup

A stray empty git repo at `D:\CarRentalApp\.git` (0 objects, 0 refs, no remote,
created by an accidental `git init` in the parent folder) was **deleted**. The
real repo is `C4_CarRentalApp\.git` — branch `master`, remote
`EngMohamedNowar/C4_CarRentalApp`. The `groot` alias also skips empty wrapper
repos automatically.

---

## 4. The profile — 11 sections

| # | Section | Lines | What it does |
|---|---|---|---|
| 0 | Configuration | 39 | project paths, service map (app/booking/catalog/customer/notification), log + run folders |
| 1 | PSReadLine | 52 | history (20 000), autocomplete, word-jump, history search, 15 key bindings |
| 2 | Prompt | 153 | Oh-My-Posh + custom theme, native fallback, **right-aligned clock** |
| 3 | Environment | 25 | UTF-8 console, .NET env vars, PATH additions |
| 4 | Core aliases | 13 | `ll`, `la`, `which`, `..`, `...` |
| 5 | General helpers | 93 | `mkcd`, `touch`, `ff`, `grep`, `json`, `ports`, `killport`, `ipinfo`, `now`, `utc`, `history-search`, `reload-profile` |
| 6 | Git | 55 | 13 aliases + helpers, `Get-GitOutput` |
| 7 | .NET | 25 | `build`, `run`, `watch`, `test`, `restore`, `publish`, `clean`, `packlist`, `outdated` |
| 8 | Docker | 18 | `dps`, `dpa`, `dc`, `docker-clean`, `docker-stop-all`, `Test-DockerReady` |
| 9 | CarRentalApp | 299 | the project-specific commands (see below) |
| 10 | Startup banner | 8 | greeting when you start in the project root |

### Project commands (section 9)

| Group | Commands |
|---|---|
| Navigation | `crr` · `crr-micro` · `crr-web` · `crr-svc <name>` · `crrhelp` · `status` |
| Running | `up <svc>` · `up <svc> -Detach` · `up-all` · `down` · `logs [svc]` · `urls` · `open-swagger <svc>` |
| Infrastructure | `infra-up` · `infra-down` · `infra-logs [svc]` · `infra-reset` · `rabbit-ui` |
| Database | `db-list` · `db-query <sql>` · `db-migrate` |
| Build | `build-all` · `test-all` · `clean-all` |

### Aliases

| Family | Aliases |
|---|---|
| Git | `gs` `gb` `glog` `gd` `gadd` `gcommit` `gac` `gpull` `gpush` `gco` `gnew` `groot` `gst` |
| .NET | `b` `br` `t` `rw` |
| Docker | `dp` |
| General | `ll` `la` `which` |

---

## 5. The prompt

### Colour palette (Nord)

Muted, low-saturation, low-contrast — nothing shouts.

| Role | Hex |
|---|---|
| terminal background | `#1C1C1C` |
| terminal foreground | `#D8DEE9` |
| cursor | `#88C0D0` |
| selection | `#3B4252` |
| user segment | bg `#3B4252` / fg `#D8DEE9` |
| path segment | bg `#434C5E` / fg `#88C0D0` |
| branch name | `#B48EAD` |
| ahead / behind | `#A3BE8C` / `#BF616A` |
| dirty indicators | `#EBCB8B` |
| stash count | `#88C0D0` |
| exit-code check | `#A3BE8C` / `#BF616A` |
| clock | `#7C8CA5` |

### Theme structure

Oh-My-Posh **theme format v4**, one left-aligned block:

```
session (diamond) → path → git → executiontime → status
```

The git segment uses inline colour tags so the branch name and the status
indicators carry different colours:

```json
"template": " \ue725 <#B48EAD>{{ .HEAD }}</>{{ if .BranchStatus }} <#A3BE8C>{{ .BranchStatus }}</>{{ end }}{{ if .Working.Changed }} <#EBCB8B>\uf044 {{ .Working.String }}</>{{ end }} ..."
```

### The clock on the right

Oh-My-Posh *can* render a right-aligned block (`"alignment": "right"`), but for
PowerShell it emits it inside the **same prompt string** — which leaves the text
cursor sitting *after* the clock, so everything you typed would appear over
there.

The profile therefore renders the clock itself and positions it with ANSI:

```
<omp prompt>  ESC[<col>G  <clock>  ESC[<promptWidth>G
```

PSReadLine honours those escapes, so the clock lands on the right edge while
the cursor stays where you are typing.

**Two traps that cost real debugging time:**

1. **Oh-My-Posh installs its `prompt` function in the *global* scope**, not in
   the module scope. Writing `& (Get-Module oh-my-posh-core) { prompt }` inside
   a replacement prompt resolves to *your own* function and recurses until
   `call depth overflow`. The profile captures the original **script block**
   (`(Get-Command prompt).ScriptBlock`) *before* replacing it — a script block
   keeps its session state, so `$script:*` variables inside it still resolve.
2. The visible width has to be measured with ANSI escapes stripped, otherwise
   the cursor lands in the wrong column.

### Toggles

| Variable | Effect |
|---|---|
| `$env:CRR_NO_CLOCK = '1'` | hide the clock |
| `$env:CRR_NO_OMP = '1'` | use the native fallback prompt instead of Oh-My-Posh |

---

## 6. Key bindings

| Key | Action |
|---|---|
| `Tab` | menu autocomplete |
| `Up` / `Down` | search history |
| `Ctrl+Up` / `Ctrl+Down` | search history (fast) |
| `Ctrl+Left` / `Ctrl+Right` | jump by word |
| `Alt+Left` / `Alt+Right` | previous / next history |
| `Ctrl+R` | reverse history search |
| `Ctrl+D` | delete character, or exit when the line is empty |
| `Ctrl+K` | kill to end of line |
| `Ctrl+C` | copy / cancel the line |
| `Ctrl+F` / `Ctrl+B` | forward / backward character |

Each binding is applied independently, so one unsupported binding never blocks
the rest.

---

## 7. Decisions & gotchas

Things that look trivial but are not.

| Decision | Why |
|---|---|
| Alias names avoid `gl`, `gc`, `gp` | those are PowerShell built-ins (`Get-Location`, `Get-Content`, `Get-ItemProperty`). Overriding them breaks scripts — hence `glog`, `gcommit`, `gpull` |
| `..` and `...` are **functions**, not aliases | PowerShell gives aliases higher precedence than functions, and an alias cannot take a positional argument |
| `Set-Alias -Option AllScope` | redefining a built-in alias with `-Scope Global` throws *"The AllScope option cannot be removed"* |
| `-ErrorAction Ignore`, not `SilentlyContinue` | `SilentlyContinue` still writes to `$Error`; `Ignore` does not. A polluted `$Error` shows up as noise on every prompt |
| `-ErrorAction Stop` inside `try`/`catch` | otherwise the failure is not catchable |
| Native git calls go through `cmd /c "... 2>nul"` | in Windows PowerShell 5.1 a native command's stderr is recorded in `$Error` **even with `2>$null`**, which would spam the error list on every keystroke |
| Oh-My-Posh theme **format v4** | segment options live under `options`, not `properties`. Using the v2 key silently breaks `max_depth`, `style: folder` and the git templates |
| The username comes from a `session` segment | there is no `user` segment type that renders a name |
| One `git` segment, not `git_branch` + `git_status` | that is how the template composes branch + working + staging + stash state |
| `settings.json` written without a BOM | Windows Terminal will not parse a BOM'd JSON file |
| `.ps1` files written **with** a BOM | so Windows PowerShell 5.1 detects UTF-8 instead of reading it as ANSI |
| `Get-Command git` checked once at load | the git helpers are only registered when git exists, and a missing tool must never break the shell |
| Every section wrapped in `try`/`catch` | a profile must never be able to break the shell |

---

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `. $PROFILE` → "not recognized" | the profile file did not exist | run `Install-CLI.ps1` |
| Prompt shows empty boxes `□` | Nerd Font missing or not applied | install it, then **restart** Windows Terminal |
| Cursor jumps after the clock | the right-aligned block was used inside the theme | the clock must be rendered by the profile, not the theme |
| `call depth overflow` on prompt | the omp prompt was called through the module instead of the captured script block | capture `(Get-Command prompt).ScriptBlock` first |
| `Set-Alias: The AllScope option cannot be removed` | an alias redefined with `-Scope Global` | use `-Option AllScope` |
| `Cannot validate argument on parameter 'Function'` | a key binding unsupported by the installed PSReadLine | bind each key separately |
| Console shows `?` instead of symbols | console codepage is 437 | the profile forces UTF-8; if a host overrides it, set `[Console]::OutputEncoding` |
| `failed to connect to the docker API` | Docker Desktop is not running | start Docker Desktop, then `infra-up` |
| `not a git repository` | you are outside the repo | `crr` or `groot` |
| Terminal settings ignored | BOM in `settings.json` | it must be UTF-8 **without** BOM |
| No autocomplete suggestions | output is redirected (CI, pipes) | expected — prediction needs a real console |

---

## 9. Work log

| Commit | Change |
|---|---|
| `aa6da70` | Add professional PowerShell CLI: profile, installer and docs |
| `3bae77a` | Add custom Nord prompt theme and soft eye-friendly terminal colours |
| `3668aa2` | Add `gac` alias: `git add --all` + `git commit -m` in one command |
| `1b2574b` | Move the clock to the right edge of the terminal |

### The original problem

```
PS D:\CarRentalApp\C4_CarRentalApp> . $PROFILE
. : The term 'C:\Users\user\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
is not recognized as the name of a cmdlet, function, script file, or operable program.
```

The profile file did not exist at all — so there was nothing to source. The
work turned it into a complete environment.

### Known outstanding items

- The **`CarRentalApp` web API does not compile** — `CarDto`, `BookingCreateDto`,
  `BookingCreateViewModel` and `Car` are missing. Pre-existing work-in-progress,
  unrelated to the CLI. The **microservices solution builds cleanly** (0 errors,
  0 warnings).
- **Docker Desktop must be running** before `infra-up`; the microservices need
  SQL Server on `localhost:1433` and RabbitMQ on `localhost:5672`. The CLI
  detects this and says so instead of throwing a raw pipe error.

---

## 10. Verifying a fresh install

```powershell
status                          # environment summary
crrhelp                         # the command reference

$global:Error.Count             # must be 0
$global:CRRUseOmp               # must be True
(Get-Module PSReadLine).Version
[Console]::OutputEncoding.WebName   # utf-8
```

```powershell
# font registered?
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' |
  Select-Object -Property *Caskaydia*

# terminal configured?
$j = Get-Content "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Raw | ConvertFrom-Json
$j.profiles.defaults.fontFace     # CaskaydiaCove NF
$j.defaultProfile                 # {574e775e-...}  (PowerShell 7)
```
