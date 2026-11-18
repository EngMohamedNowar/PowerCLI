# PowerCLI — Command Reference

A professional PowerShell environment for Windows developers: a rich prompt,
smart aliases, and general-purpose commands for git, .NET, Docker and the shell.

> **Looking for the full picture?** See **[README.md](README.md)** — what the
> system is, the colour palette, and the install one-liner.
> **[SETUP-CLI.md](SETUP-CLI.md)** has the step-by-step reproduction guide, and
> **[DESIGN.md](DESIGN.md)** explains every problem solved along the way.

---

## 1. How to run it

Everything is already installed and wired up. Open a terminal and you're done.

### Option A — Windows Terminal (recommended)

```
Win + R  ->  wt
```

### Option B — PowerShell 7 (new shell, faster, has `&&` and `? :`)

```
Win + R  ->  pwsh
```

### Option C — Classic Windows PowerShell 5.1

```
Win + R  ->  powershell
```

All three load the same profile. You do **not** need to run `. $PROFILE` manually
anymore — the file exists and loads automatically.

### Verify it worked

```powershell
status      # environment summary
psclihelp   # full command reference
```

---

## 2. Where things live

| What | Path |
|---|---|
| Profile bootstrap (PS 5.1) | `%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |
| Profile bootstrap (PS 7)   | `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| **The real implementation** | `%USERPROFILE%\Documents\PowerShell\PowerCLI.ps1` |
| **The prompt theme** | `%USERPROFILE%\Documents\PowerShell\themes\powercli.omp.json` |

> **To customise the CLI, edit `PowerCLI.ps1` only.** The two
> `Microsoft.PowerShell_profile.ps1` files are one-line loaders — leave them alone.
>
> Apply changes immediately without restarting the shell:
> ```powershell
> reload-profile
> ```

---

## 3. Installed stack

| Tool | Version | Notes |
|---|---|---|
| Git | 2.56.0 | newly installed, was missing |
| PowerShell | 7.7.0 | newly installed (MSIX) |
| Oh-My-Posh | 32.1.0 | custom Nord theme `powercli.omp.json` |
| PSReadLine | 2.0.0 (PS 5.1) / 2.4.5 (PS 7) | history, autocomplete, key bindings |
| .NET SDK | 10.0.401 | projects target `net8.0` |
| Docker Desktop | 29.8.0 | **daemon must be running** |
| SQL Server Client | 170 | used by `db-query` |
| CaskaydiaCove NF | 3.5.1 | Nerd Font — required for the prompt icons |

### Key bindings

| Key | Action |
|---|---|
| `Tab` | menu autocomplete |
| `Up` / `Down` | search history |
| `Ctrl+Left` / `Ctrl+Right` | jump by word |
| `Alt+Left` / `Alt+Right` | previous / next history |
| `Ctrl+R` | reverse history search |
| `Ctrl+D` | delete char or exit |
| `Ctrl+K` | kill to end of line |
| `Ctrl+Space` | *(PS 7 only)* autocomplete |

---

## 4. Command reference

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
> `gc` = `Get-Content`, `gp` = `Get-ItemProperty` are left untouched).

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
| `db-list` | list databases |
| `db-query <sql>` | run a SQL query (localhost,1433) |

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

## 5. Colour palette (Nord)

Everything uses the **Nord** palette — muted, low-saturation and
low-contrast, so nothing shouts during a long session.

| Where | Hex |
|---|---|
| terminal background | `#1C1C1C` (soft charcoal, not pure black) |
| terminal foreground | `#D8DEE9` (off-white, not pure white) |
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

## 6. Toggles

| Variable | Effect |
|---|---|
| `$env:POWERCLI_NO_CLOCK = '1'` | hide the clock |
| `$env:POWERCLI_NO_OMP = '1'` | use the built-in native prompt instead of Oh-My-Posh |
| `$env:POWERCLI_PLAIN = '1'` | force the glyph-free theme (no Nerd Font icons) |
| `$env:POWERCLI_FORCE_GLYPHS = '1'` | force the Nerd Font theme even if detection says otherwise |

Apply changes without restarting:

```powershell
reload-profile
```

---

## 7. Troubleshooting

| Symptom | Fix |
|---|---|
| Prompt shows empty boxes `□` | The profile auto-detects this and loads the plain theme. If boxes persist, set `$env:POWERCLI_PLAIN='1'` and run `reload-profile`, then restart Windows Terminal |
| `. $PROFILE` → "not recognized" | run `Install-CLI.ps1` |
| Console shows `?` instead of symbols | console codepage is 437 — the profile forces UTF-8 |
| Terminal settings ignored | `settings.json` must be UTF-8 **without** BOM |
| No autocomplete suggestions | output is redirected (CI, pipes) — expected |
| Icons missing in VS Code / ConEmu | set that terminal's font to `CaskaydiaCove NF` manually |

---

## 8. Files

```
PowerCLI/
├── README.md                          ← overview, install, quick reference
├── README-CLI.md                      ← this file (command reference)
├── SETUP-CLI.md                       ← step-by-step reproduction guide
├── DESIGN.md                          ← every problem solved, and why
├── assets/
│   └── prompt.png                     ← screenshot
└── tools/powershell/
    ├── PowerCLI.ps1                   ← the profile (678 lines)
    ├── Install-CLI.ps1                ← idempotent installer
    └── themes/
        ├── powercli.omp.json          ← glyph theme (Nerd Font)
        └── powercli-plain.omp.json    ← glyph-free fallback theme
```

`tools/powershell/` is **self-contained** — copying just that folder to a new
machine and running `Install-CLI.ps1` is enough.

---

## License

Personal project. Feel free to fork and adapt.
