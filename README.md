# PowerCLI

> A polished, self-contained PowerShell environment for Windows developers —
> a git-aware prompt, smart aliases, and a one-command installer.

![Platform](https://img.shields.io/badge/platform-Windows-0078D6?style=flat-square&logo=windows10)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE?style=flat-square&logo=powershell)
![Prompt](https://img.shields.io/badge/prompt-Oh--My--Posh%20%2B%20Nord-2F9CC9?style=flat-square)
![Errors](https://img.shields.io/badge/load%20errors-0-brightgreen?style=flat-square)
![Lines](https://img.shields.io/badge/profile-678%20lines-lightgrey?style=flat-square)

![PowerCLI prompt](assets/prompt.png)

---

## Contents

- [Why PowerCLI](#why-powercli)
- [Install](#install)
- [Quick start](#quick-start)
- [Command reference](#command-reference)
- [Prompt & theme](#prompt--theme)
- [Configuration](#configuration)
- [How it works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Project layout](#project-layout)

---

## Why PowerCLI

The stock PowerShell prompt gives you none of the context you actually need.
PowerCLI adds it in one install:

| | |
|---|---|
| **Git at a glance** | branch, ahead/behind, modified files and stash count, without running `git status` |
| **Right-aligned clock** | pinned to the right edge — and it stays there after a resize, without stealing your typing position |
| **Nord palette** | muted, low-contrast colours that stay readable over a long session |
| **48 commands + 21 aliases** | git, .NET, Docker, SQL and shell helpers under short names |
| **Font auto-detection** | falls back to a glyph-free theme so you never see `□` boxes |
| **Idempotent installer** | one command on a fresh machine; safe to run twice |
| **Zero load errors** | verified on PowerShell 5.1 and 7+ |

---

## Install

### One-liner

```powershell
iex ((irm https://raw.githubusercontent.com/EngMohamedNowar/PowerCLI/main/tools/powershell/Install-CLI.ps1).TrimStart([char]0xFEFF))
```

### From a clone

```powershell
git clone https://github.com/EngMohamedNowar/PowerCLI.git
cd PowerCLI
.\tools\powershell\Install-CLI.ps1
```

Then **close and reopen Windows Terminal** — this is required for the font to
take effect.

### What the installer does

| # | Step | Notes |
|---|---|---|
| 1 | Execution policy → `RemoteSigned` | current user scope |
| 2 | Git + PowerShell 7 + Oh-My-Posh | via `winget`, only if missing |
| 3 | CaskaydiaCove NF Nerd Font | per-user, **no admin required** |
| 4 | Patch Windows Terminal | font, Nord palette, PS 7 as default |
| 5 | Write profile files | both PS 5.1 and PS 7 bootstraps |
| 6 | Verify | confirms every component is detected |

### Installer options

| Flag | Effect |
|---|---|
| `-SkipTools` | skip winget (Git / PowerShell 7 already present) |
| `-SkipFont` | skip the Nerd Font download / registration |
| `-ForceFont` | re-register the font even if already present |

The installer is **idempotent** — running it twice is safe.

> **OneDrive?** If your Documents folder is redirected to OneDrive, the
> installer detects it through `$PROFILE` and writes to the correct location
> automatically. No manual copying.

---

## Quick start

```powershell
status        # environment summary
psclihelp     # full command reference
```

---

## Command reference

> Full tables with key bindings live in **[README-CLI.md](README-CLI.md)**.

### Navigation

| Command | Description |
|---|---|
| `mkcd <path>` | create a directory and enter it |
| `..` / `...` | up one / two levels |
| `ff <name>` | find files by name (recursive) |
| `grep <pattern>` | search file contents |
| `psclihelp` | show the command reference |
| `status` | environment summary |

### Git

| Command | Description |
|---|---|
| `gs` | `git status -sb` |
| `gb` | `git branch -v` |
| `glog` | `git log --oneline --graph --decorate` |
| `gd` / `gadd` | `git diff` / `git add` |
| `git-staged` | `git diff --staged` |
| `gcommit <msg>` | `git commit -m` |
| `gac <msg>` | `git add --all` + `git commit -m` in one go |
| `gpull` / `gpush` | `git pull --rebase` / `git push` |
| `gco <branch>` | `git checkout` |
| `gnew <branch>` | create and switch to a new branch |
| `groot` | jump to the repository root |
| `gst` | `git stash` |
| `git-undo` | `git reset --soft HEAD~1` |

> Alias names deliberately avoid PowerShell built-ins (`gl` = `Get-Location`,
> `gc` = `Get-Content`, `gp` = `Get-ItemProperty`).

### Build / Test (.NET)

| Command | Description |
|---|---|
| `build [proj]` | `dotnet build` |
| `run [proj]` | `dotnet run` |
| `watch [proj]` | `dotnet watch` |
| `test [proj]` | `dotnet test` |
| `restore [proj]` | `dotnet restore` |
| `publish [proj]` | `dotnet publish` |
| `clean [proj]` | `dotnet clean` |
| `packlist [proj]` | list packages (transitive) |
| `outdated [proj]` | list outdated packages |
| `dotnetinfo` | SDK version + installed runtimes |
| `b` / `br` / `t` / `rw` | build / run / test / restore |

### Docker

| Command | Description |
|---|---|
| `dps` / `dp` | `docker ps` |
| `dpa` | `docker ps -a` |
| `dc <args>` | `docker compose <args>` |
| `docker-clean` | prune everything |
| `docker-stop-all` | stop all containers |

### Database / SQL

Available only when `sqlcmd` is installed.

| Command | Description |
|---|---|
| `db-query <sql>` | run a SQL query (localhost,1433) |
| `db-list` | list databases |

### General

| Command | Description |
|---|---|
| `touch <file>` | create a file, or update its timestamp |
| `json <file>` | pretty-print JSON |
| `ports [port]` | show listening ports |
| `killport <port>` | kill the process on a port |
| `ipinfo` | local + public IP |
| `now` / `utc` | timestamps |
| `history-search <term>` | search command history |
| `reload-profile` | re-apply the profile |

---

## Prompt & theme

```
 user │ 📁 my-project │ ⎇ master ↑1 ✎ ?1 ~2 │ ✔          🕐 13:20:48
 slate   ice blue        mauve  grn  amb    ice   dim
                        ↑ left side                    ↑ right edge
```

The clock is rendered by the profile itself using ANSI cursor positioning, so
the text cursor stays on the left while the clock sits on the right edge.

### Colour palette (Nord)

| Where | Hex |
|---|---|
| background | `#1C1C1C` — soft charcoal, not pure black |
| foreground | `#D8DEE9` — off-white, not pure white |
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

---

## Configuration

Set these before the profile loads (or export and run `reload-profile`).

| Variable | Effect |
|---|---|
| `$env:POWERCLI_NO_CLOCK = '1'` | hide the clock |
| `$env:POWERCLI_NO_OMP = '1'` | use the built-in native prompt instead of Oh-My-Posh |
| `$env:POWERCLI_PLAIN = '1'` | force the glyph-free theme (no Nerd Font icons) |
| `$env:POWERCLI_FORCE_GLYPHS = '1'` | force the Nerd Font theme even if detection says otherwise |

```powershell
reload-profile    # apply changes without restarting the shell
```

---

## How it works

`tools/powershell/` is the source of truth; everything else is generated.

```powershell
$profileDir   = Split-Path $PROFILE          # handles OneDrive redirection
$documentsDir = Split-Path $profileDir
$SharedDir    = Join-Path $documentsDir 'PowerShell'
```

The profile loads in sections — PSReadLine, prompt, encoding, aliases, then
per-tool helpers — and **every section is wrapped so a failure can never break
the shell**.

Three details worth knowing:

- **Font detection is cheap on purpose.** `Test-PowerCLINerdFont` reads the
  Windows Terminal config and the font registry; it never calls `Add-Type`,
  because compiling C# costs ~470 ms and would blow the 500 ms startup budget.
- **Nerd Font glyphs are private-use codepoints.** Without the font they render
  as `□`, so a glyph-free theme (`powercli-plain.omp.json`) is loaded instead.
- **Errors use `-ErrorAction Ignore`.** `SilentlyContinue` still writes to
  `$Error`, which would pollute the error list on every keystroke.

The full list of problems solved during development — and why the code is
shaped the way it is — is in **[DESIGN.md](DESIGN.md)**.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Prompt shows empty boxes `□` | The profile auto-detects this and loads the plain theme. If boxes persist, set `$env:POWERCLI_PLAIN='1'` and run `reload-profile`, then restart Windows Terminal |
| `. $PROFILE` → "not recognized" | run `Install-CLI.ps1` |
| Console shows `?` instead of symbols | codepage is 437 — the profile forces UTF-8 |
| Terminal settings ignored | `settings.json` must be UTF-8 **without** BOM |
| No autocomplete suggestions | output is redirected (CI, pipes) — expected |
| Icons missing in VS Code / ConEmu | set that terminal's font to `CaskaydiaCove NF` manually |

---

## Project layout

```
PowerCLI/
├── README.md                      ← you are here
├── README-CLI.md                  ← detailed command reference + key bindings
├── SETUP-CLI.md                   ← step-by-step reproduction guide
├── DESIGN.md                      ← every problem solved, and why
├── assets/
│   └── prompt.png                 ← screenshot
└── tools/powershell/              ← self-contained; copy this to a new machine
    ├── PowerCLI.ps1               ← the profile (678 lines)
    ├── Install-CLI.ps1            ← idempotent installer
    └── themes/
        ├── powercli.omp.json      ← glyph theme (Nerd Font)
        └── powercli-plain.omp.json← glyph-free fallback theme
```

`tools/powershell/` is **self-contained** — copying just that folder to a new
machine and running `Install-CLI.ps1` is enough.

---

## Related documentation

| File | Contents |
|---|---|
| **[README-CLI.md](README-CLI.md)** | full command reference, key bindings, installed stack |
| **[SETUP-CLI.md](SETUP-CLI.md)** | step-by-step reproduction guide, registry/terminal settings |
| **[DESIGN.md](DESIGN.md)** | the 14 problems solved, and the reasoning behind each |

---

## License

Personal project. Feel free to fork and adapt.
