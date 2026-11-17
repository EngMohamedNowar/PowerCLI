# CarRentalApp CLI

A professional PowerShell environment for this repo: a rich prompt, smart aliases,
and project-aware commands for running the microservices.

> **Looking for the full picture?** See **[CLI.md](CLI.md)** — what the system is,
> what changed on the machine, and why each decision was made.
> **[SETUP-CLI.md](SETUP-CLI.md)** has the step-by-step reproduction guide.

---

## 1. How to run it

> **Setting this up on a new machine?** See **[SETUP-CLI.md](SETUP-CLI.md)** -
> it has a one-command installer plus every file and setting that was changed.

Everything is already installed and wired up. Open a terminal and you're done.

### Option A - Windows Terminal (recommended)

```
Win + R  ->  wt
```

### Option B - PowerShell 7 (new shell, faster, has `&&` and `? :`)

```
Win + R  ->  pwsh
```

### Option C - Classic Windows PowerShell 5.1

```
Win + R  ->  powershell
```

All three load the same profile. You do **not** need to run `. $PROFILE` manually
anymore - the file exists and loads automatically.

### Verify it worked

```powershell
status      # environment summary
crrhelp     # full command reference
```

---

## 2. Where things live

| What | Path |
|---|---|
| Profile bootstrap (PS 5.1) | `C:\Users\user\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |
| Profile bootstrap (PS 7)   | `C:\Users\user\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| **The real implementation** | `C:\Users\user\Documents\PowerShell\CarRentalProfile.ps1` |

> **To customise the CLI, edit `CarRentalProfile.ps1` only.** The two
> `Microsoft.PowerShell_profile.ps1` files are one-line loaders - leave them alone.
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
| Oh-My-Posh | 32.1.0 | custom Nord theme `carrental.omp.json` |
| PSReadLine | 2.0.0 (PS 5.1) / 2.4.5 (PS 7) | history, autocomplete, key bindings |
| .NET SDK | 10.0.401 | projects target `net8.0` |
| Docker Desktop | 29.8.0 | **daemon must be running** |
| SQL Server Client | 170 | used by `db-query` |
| CaskaydiaCove NF | 3.5.1 | Nerd Font - required for the prompt icons |

### Colours

Everything uses the **Nord** palette - muted, low-saturation and
low-contrast, so nothing shouts during a long session.

| Where | Setting |
|---|---|
| terminal background | `#1C1C1C` (soft charcoal, not pure black) |
| terminal foreground | `#D8DEE9` (off-white, not pure white) |
| cursor | `#88C0D0` |
| selection | `#3B4252` |
| prompt theme | `tools/powershell/themes/carrental.omp.json` |

```
 user │ 📁 C4_CarRentalApp │ ⎇ master ↑1 ✎ ?1 ~2 │ ✔          🕐 13:08:30
 slate   ice blue          mauve  grn  amb    ice   dim
                        ↑ left side                    ↑ right edge
```

The clock is pinned to the **right edge** of the terminal while the text cursor
stays on the left, so typing is never disturbed by it.

| Toggle | Effect |
|---|---|
| `$env:CRR_NO_CLOCK = '1'` | hide the clock |
| `$env:CRR_NO_OMP = '1'` | use the built-in native prompt instead of Oh-My-Posh |

Edit the theme and run `reload-profile` to see changes instantly.

### Nerd Font (why the prompt had empty boxes)

Oh-My-Posh themes use icons from the Nerd Fonts private-use area. Without a
Nerd Font installed, the terminal shows empty boxes instead of the icons.

**CaskaydiaCove NF** is now installed for your user account and set as the
Windows Terminal font:

- font files: `%LOCALAPPDATA%\Microsoft\Windows\Fonts\CaskaydiaCoveNerdFont-*.ttf`
- registry: `HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts`
- Windows Terminal `profiles.defaults.fontFace` = `CaskaydiaCove NF`
- Windows Terminal default profile switched to **PowerShell 7** (`pwsh`)

If you ever reset the Terminal settings, put this back in `settings.json`:

```json
"profiles": { "defaults": { "fontFace": "CaskaydiaCove NF" } }
```

The full font set is at
<https://github.com/ryanoasis/nerd-fonts/releases> (v3.5.1).

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

## 4. Everyday workflow

```powershell
crr                 # jump to the project root
infra-up            # start SQL Server + RabbitMQ in Docker
up-all              # launch all 4 microservices in the background
urls                # show every URL
open-swagger catalog
logs catalog        # tail the service log
down                # stop all background services
```

### Running one service in the foreground

```powershell
up booking          # Ctrl+C to stop
up booking -Detach  # run in the background instead
```

### Services

| Key | Project | URL |
|---|---|---|
| `app` | `CarRentalApp` (web API) | http://localhost:5077/swagger |
| `booking` | `Booking.API` | http://localhost:60481/swagger |
| `catalog` | `Catalog.API` | http://localhost:60480/swagger |
| `customer` | `Customer.API` | http://localhost:60478/swagger |
| `notification` | `Notification.API` | http://localhost:60479/swagger |

Infrastructure: RabbitMQ UI on http://localhost:15672 (`guest` / `guest`),
SQL Server on `localhost:1433` (`sa` / `Your_password123`).

---

## 5. Command reference

### Navigation
| Command | Description |
|---|---|
| `crr` | go to the project root |
| `crr-micro` | go to `CarRental.Microservices` |
| `crr-web` | go to the `CarRentalApp` web API |
| `crr-svc <name>` | go to a service folder |
| `..` / `...` | up one / two levels |
| `crrhelp` | show the command reference |
| `status` | environment summary |

### Infrastructure
| Command | Description |
|---|---|
| `infra-up` | start SQL Server + RabbitMQ |
| `infra-down` | stop the compose stack |
| `infra-logs [svc]` | tail compose logs |
| `infra-reset` | stop and wipe volumes (fresh DB) |
| `rabbit-ui` | open the RabbitMQ management UI |

### Running
| Command | Description |
|---|---|
| `up <svc>` | run a service in the foreground |
| `up <svc> -Detach` | run a service in the background |
| `up-all` | run all microservices in the background |
| `down` | stop all background services |
| `logs [svc] [-Follow]` | show service logs |
| `urls` | list every service URL |
| `open-swagger <svc>` | open Swagger UI |

### Database
| Command | Description |
|---|---|
| `db-list` | list `CarRental%` databases |
| `db-query <sql>` | run a SQL query |
| `db-migrate` | apply EF Core migrations |

### Build / Test
| Command | Description |
|---|---|
| `build-all` | build every project |
| `test-all` | run all tests |
| `clean-all` | clean `bin`/`obj` everywhere |
| `b` / `br` / `t` / `rw` | build / run / test / restore |

### Git
| Command | Description |
|---|---|
| `gs` | `git status -sb` |
| `gb` | `git branch -v` |
| `glog` | `git log --oneline --graph --decorate` |
| `gd` / `gadd` | `git diff` / `git add` |
| `gcommit <msg>` | `git commit -m` |
| `gac <msg>` | `git add --all` + `git commit -m` in one go |
| `gpull` / `gpush` | `git pull --rebase` / `git push` |
| `gco <branch>` | `git checkout` |
| `gnew <branch>` | create and switch to a new branch |
| `groot` | jump to the repository root |
| `gst` | `git stash` |

> Alias names deliberately avoid PowerShell built-ins (`gl` = `Get-Location`,
> `gc` = `Get-Content`, `gp` = `Get-ItemProperty` are left untouched).

### General
| Command | Description |
|---|---|
| `mkcd <path>` | create a directory and enter it |
| `ff <name>` | find files by name (recursive; `-Shallow` to limit) |
| `grep <pattern>` | search file contents |
| `json <file>` | pretty-print JSON |
| `ports [port]` | show listening ports |
| `killport <port>` | kill the process on a port |
| `ipinfo` | local + public IP |
| `now` / `utc` | timestamps |
| `history-search <term>` | search command history |
| `reload-profile` | re-apply the profile |

### Troubleshooting

| Symptom | Fix |
|---|---|
| Oh-My-Posh prompt looks wrong | `$env:CRR_NO_OMP = '1'` forces the built-in fallback prompt |
| Want a different prompt theme | change `Theme` in `CarRentalProfile.ps1` (`jandedobbeleer`, `powerlevel10k_rainbow`, `atomic`, `tokyo`, `blueish`) |
| Console shows `?` instead of symbols | already handled - the profile forces UTF-8 |
| `not a git repository` | you are outside the repo; `crr` or `groot` to jump in |

---

## 6. Notes and caveats

- **Docker Desktop must be running** before `infra-up` or the microservices
  (they need SQL Server on `localhost:1433` and RabbitMQ on `localhost:5672`).
  The CLI detects this and tells you instead of throwing a raw pipe error.
- **`CarRentalApp` (the web API) currently does not compile** - `CarDto`,
  `BookingCreateDto`, `BookingCreateViewModel` and `Car` are missing. The
  microservices solution builds cleanly (0 errors, 0 warnings).
- **Logs** are written to `%TEMP%\CarRentalApp\logs`, PID files to
  `%TEMP%\CarRentalApp\run`. Nothing is written into the repository.
- **A stray empty git repo** at `D:\CarRentalApp\.git` (0 objects, 0 refs, no remote)
  was left over from an accidental `git init` in the parent folder. It has been
  **deleted**. The real repo is `D:\CarRentalApp\C4_CarRentalApp\.git`
  (branch `master`, remote `EngMohamedNowar/C4_CarRentalApp`).
