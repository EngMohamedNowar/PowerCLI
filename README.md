# PowerCLI — Professional PowerShell CLI

A complete, self-contained PowerShell environment for Windows developers:

- **Prompt**: Oh-My-Posh with a custom **Nord** theme — muted, eye-friendly colours
- **Right-aligned clock** that stays on the right edge (even after a terminal resize)
- **Nerd Font** (CaskaydiaCove NF) for crisp icons
- **41 functions + 21 aliases** for navigation, git, .NET, Docker and microservices
- **Idempotent installer** — one command on a fresh machine
- **0 errors** on load (PS 5.1 and PS 7)

```
 user │ 📁 C4_CarRentalApp │ ⎇ master ↑1 ✎ ?1 ~2 │ ✔          🕐 13:20:48
 slate   ice blue          mauve  grn  amb    ice   dim
                        ↑ left side                    ↑ right edge
```

![PowerCLI prompt](assets/prompt.png)

The clock is pinned to the right edge of the terminal while the text cursor
stays on the left, so typing is never disturbed by it.

---

## Install (one command)

```powershell
iex (irm https://raw.githubusercontent.com/EngMohamedNowar/PowerCLI/main/tools/powershell/Install-CLI.ps1)
```

Or from a clone:

```powershell
git clone https://github.com/EngMohamedNowar/PowerCLI.git
cd PowerCLI
.\tools\powershell\Install-CLI.ps1
```

Then **close and reopen Windows Terminal** (required for the font).

### What the installer does

1. Sets the execution policy to `RemoteSigned`
2. Installs **Git** + **PowerShell 7** via `winget` (if missing)
3. Downloads and registers the **CaskaydiaCove NF** Nerd Font (per user, no admin)
4. Patches Windows Terminal: font + soft Nord palette + PowerShell 7 as default
5. Writes the profile files (PS 5.1 and PS 7)
6. Verifies everything

### Installer options

| Flag | Effect |
|---|---|
| `-SkipTools` | don't touch winget (Git / PowerShell 7 already present) |
| `-SkipFont` | don't download / register the Nerd Font |
| `-ForceFont` | re-register the font even if already present |

The installer is **idempotent** — running it twice is safe.

---

## Run it

```powershell
status      # environment summary
crrhelp     # full command reference
```

### Everyday workflow

```powershell
crr                 # jump to the project root
infra-up            # start SQL Server + RabbitMQ (Docker)
up-all              # launch all microservices in the background
urls                # show every URL
open-swagger catalog
logs catalog        # tail the service log
down                # stop all background services
```

### Running one service

```powershell
up booking          # in the foreground (Ctrl+C to stop)
up booking -Detach  # in the background
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

## Command reference

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
| `ff <name>` | find files by name (recursive) |
| `grep <pattern>` | search file contents |
| `json <file>` | pretty-print JSON |
| `ports [port]` | show listening ports |
| `killport <port>` | kill the process on a port |
| `ipinfo` | local + public IP |
| `now` / `utc` | timestamps |
| `history-search <term>` | search command history |
| `reload-profile` | re-apply the profile |

---

## Colour palette (Nord)

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

## Files

```
PowerCLI/
├── README.md                          ← this file
├── README-CLI.md                      ← detailed command reference
├── SETUP-CLI.md                       ← step-by-step reproduction guide
└── tools/powershell/
    ├── CarRentalProfile.ps1           ← the CLI (792 lines)
    ├── Install-CLI.ps1                ← idempotent installer
    └── themes/
        └── carrental.omp.json         ← the prompt theme
```

`tools/powershell/` is **self-contained** — copying just that folder to a new
machine and running `Install-CLI.ps1` is enough.

---

## Toggles

| Variable | Effect |
|---|---|
| `$env:CRR_NO_CLOCK = '1'` | hide the clock |
| `$env:CRR_NO_OMP = '1'` | use the built-in native prompt instead of Oh-My-Posh |

Apply changes without restarting:

```powershell
reload-profile
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Prompt shows empty boxes `□` | Nerd Font missing — restart Windows Terminal after install |
| `. $PROFILE` → "not recognized" | run `Install-CLI.ps1` |
| Console shows `?` instead of symbols | console codepage is 437 — the profile forces UTF-8 |
| `failed to connect to the docker API` | start Docker Desktop, then `infra-up` |
| `not a git repository` | you are outside the repo — `crr` or `groot` |
| Terminal settings ignored | `settings.json` must be UTF-8 **without** BOM |
| No autocomplete suggestions | output is redirected (CI, pipes) — expected |

---

## License

Personal project. Feel free to fork and adapt. See the
[CarRentalApp repo](https://github.com/EngMohamedNowar/C4_CarRentalApp) for
the original context.
