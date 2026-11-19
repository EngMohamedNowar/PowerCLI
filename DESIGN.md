# PowerCLI — Design Notes

Every problem below was hit while building PowerCLI on a real Windows dev
machine, and every one of them shaped the code. Read this if you want to know
*why* the profile is written the way it is — not just what it does.

> **Looking for the big picture?** [README.md](README.md) covers install,
> commands and configuration. [SETUP-CLI.md](SETUP-CLI.md) is the
> step-by-step reproduction guide.

---

## 1. Git branch not showing in the traditional CLI

The default PowerShell prompt does **not** show the current git branch. You had
to run `git status` or `git branch` every time. PowerCLI's prompt shows the
branch, ahead/behind counts, modified files and stash count at a glance:

```
⎇ master ↑1 ✎ ?1 ~2
```

## 2. `PowerShell 7.7.0` startup banner

When opening PowerShell 7, the banner `PowerShell 7.7.0` + copyright line
printed on every launch. Fixed two ways:

- Windows Terminal `commandline` now includes `-NoLogo` — applied to **every**
  PowerShell entry, not just PowerShell 7 (see #15)
- The profile calls `Clear-Host` on first load, so even `pwsh` opened from the
  Run dialog is clean

## 3. Icons showing as empty boxes `□`

Oh-My-Posh themes use Nerd Font glyphs. Without a Nerd Font installed, the
terminal renders them as empty boxes. Fixed by:

- Installing **CaskaydiaCove NF** (v3.5.1) per-user (no admin)
- Registering it in `HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts`
- Setting Windows Terminal `profiles.defaults.fontFace = "CaskaydiaCove NF"`

## 4. Profile not found (`$PROFILE` points to OneDrive)

On machines where Documents is redirected to OneDrive, PowerShell's `$PROFILE`
points at `C:\Users\<you>\OneDrive\Documents\...` but hardcoded paths in the
scripts pointed at `C:\Users\<you>\Documents\...`. Fixed by deriving every path
from `$PROFILE`:

```powershell
$profileDir   = Split-Path $PROFILE
$documentsDir = Split-Path $profileDir
$SharedDir    = Join-Path $documentsDir 'PowerShell'
```

Works on any machine, with or without OneDrive.

## 5. Clock not fixed on the right

Oh-My-Posh's right-aligned block renders inside the *same* prompt string,
leaving the text cursor sitting **after** the clock, so everything you typed
appeared over there. Fixed by rendering the clock ourselves with ANSI cursor
positioning, leaving the cursor where you are typing.

## 6. Clock wraps onto the next line after a resize

PSReadLine caches the prompt string and re-draws it on a resize, so the
clock's absolute column went stale and wrapped. Fixed with a 500 ms timer
that detects the width change and calls `Invoke-PoshPromptRepaint`, then writes
`ESC[1B ESC[2K ESC[1A` to clear any stale clock on the next line.

## 7. `iex (irm ...)` not working

`Invoke-Expression` cannot parse scripts with a BOM or `[CmdletBinding()]`.
Fixed by removing both from the installer and documenting the working one-liner:

```powershell
iex ((irm <url>).TrimStart([char]0xFEFF))
```

## 8. `Set-Alias: The AllScope option cannot be removed`

Redefining a built-in alias (like `cat`, `clear`, `gl`) with `-Scope Global`
throws because those aliases have the `AllScope` option. Fixed by using
`-Option AllScope` for every alias.

## 9. `Cannot validate argument on parameter 'Function'`

Several key bindings (`CopyOrCancel`, `AddToHistory`, `Ctrl+Space`) are not
valid in older PSReadLine versions. Fixed by binding each key individually
inside a try/catch so one failure never blocks the rest.

## 10. `$Error` polluted on every keystroke

`-ErrorAction SilentlyContinue` still writes to `$Error`. `Ignore` does not.
Native git stderr is recorded in `$Error` even with `2>$null`. Fixed by using
`-ErrorAction Ignore` everywhere and routing native git calls through
`cmd /c "... 2>nul"`.

## 11. Oh-My-Posh module not registered

The `oh-my-posh` PowerShell module is not in `$PSModulePath` on a fresh
install. Fixed by using `oh-my-posh init pwsh` which emits a ready-to-run
init script — no module registration needed.

## 12. Stray empty git repo in the parent folder

An accidental `git init` left an empty repo (0 objects, 0 refs, no remote) in a
parent directory. It made `git status` show the wrapper folder as untracked
instead of the real repo's status. `groot` now skips empty wrapper repos
automatically, and the stray `.git` was removed.

## 13. Console shows `?` instead of symbols

The console codepage was IBM437. Fixed by forcing UTF-8:
`[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`.

## 14. Users see weird symbols (empty boxes) in the prompt

Users who ran PowerCLI in a terminal that was **not** using a Nerd Font saw the
prompt icons as empty boxes / tofu. The old code always loaded the glyph theme,
so a missing or unselected font guaranteed broken output.

Fixed with automatic detection at load time:

- `Test-PowerCLINerdFont` checks — cheaply, with **no `Add-Type`** (compiling
  C# costs ~470 ms, which would blow the 500 ms profile budget):
  1. `POWERCLI_PLAIN` / `POWERCLI_FORCE_GLYPHS` overrides
  2. Windows Terminal `settings.json` `fontFace` (authoritative when
     `WT_SESSION` is set)
  3. the per-user / system font registry for any installed Nerd Font
- If a Nerd Font is usable → the glyph theme loads as before.
- If not → the new `powercli-plain.omp.json` loads instead: same Nord palette
  and git status, but only plain Unicode (uses `.Ref` instead of `.HEAD`,
  because `.HEAD` injects the `U+E0A0` branch icon).
- The right-hand clock drops its `U+F017` icon when no Nerd Font is present.

Result: **zero tofu boxes in any terminal**, with the full experience kept for
terminals that do have the font.

## 15. `Loading personal and system profiles took 1415ms.` on startup

A user screenshot showed this line above the prompt. It is printed by the host
**after** the profile finishes, and only when the combined load time exceeds
**500 ms** — a hard-coded threshold with no environment variable to disable it.

Two things were wrong:

**a) `-NoLogo` was only applied to PowerShell 7.** That switch is the only
supported way to suppress the message, but the installer patched just the
`Windows.Terminal.PowershellCore` entry, so the classic **Windows PowerShell
5.1** tab still printed it. The installer now walks *every* profile in
`settings.json` whose `commandline` matches `powershell.exe` / `pwsh.exe` and
appends `-NoLogo` to any that lacks it.

**b) The workaround in the profile never worked.** SECTION 10 used to spawn a
background runspace that slept for a second and called `Clear-Host` to wipe the
message. A background runspace has no interactive host, so `Clear-Host` always
threw *"A command that prompts the user failed because the host program … does
not support user interaction"* and the `catch` swallowed it — while still paying
for a runspace on every start. It is gone; the intent is documented in place.

Verified by probe: with a deliberately slowed profile, `-NoExit -File` prints
the message and `-NoLogo -NoExit -File` does not.

Remaining case: launching `pwsh` from the Run dialog passes no `-NoLogo`, so a
genuinely slow machine can still show the message. Speed is the only lever
there — see the load-time breakdown below.

### Where the load time goes

Measured on a warm profile (~510 ms total, i.e. right at the threshold):

| Part | Cost |
|---|---|
| `oh-my-posh init` + `Invoke-Expression` | ~208 ms |
| `Import-Module PSReadLine` | ~102 ms |
| PSReadLine options + 15 key bindings | ~74 ms |
| `Get-Module -ListAvailable PSReadLine` | ~43 ms |
| Nerd Font detection, PATH, encoding, aliases | rest |

Cold start is worse (JIT + antivirus), which is what produced the 1415 ms
figure. Note that `Add-Type` was deliberately avoided in the font check: it
costs ~470 ms on its own.

---

## Design decisions worth knowing

- **Alias names avoid PowerShell built-ins.** `gl` (= `Get-Location`),
  `gc` (= `Get-Content`) and `gp` (= `Get-ItemProperty`) are left untouched —
  that's why the git aliases are `glog`, `gcommit`, `gpull` instead.
- **`..` and `...` are functions, not aliases.** PowerShell gives aliases a
  higher precedence than functions, and an alias cannot take a positional
  argument.
- **Errors use `-ErrorAction Ignore`, not `SilentlyContinue`.** `SilentlyContinue`
  still writes to `$Error`; `Ignore` does not.
- **Native git calls go through `cmd /c "... 2>nul"`.** In Windows PowerShell
  5.1 a native command's stderr is recorded in `$Error` **even with `2>$null`**.
- **Oh-My-Posh theme format v4** — segment options live under `options`, not
  `properties`. Using the v2 `properties` key silently breaks `max_depth`,
  `style: folder` and the git templates.
- **One `git` segment, not `git_branch` + `git_status`** — that is how the
  template composes branch + working + staging + stash state.
- **The right-aligned clock is rendered by the profile, not the theme.**
- **The profile never throws.** Every section is wrapped so a failure can never
  break the shell.
