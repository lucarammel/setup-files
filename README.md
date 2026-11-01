# setup-files

My Zed config + shell setup + project bootstrap scripts.

## Installation

```bash
git clone <repo-url> ~/setup-files && cd ~/setup-files && sh install.sh
```

The script detects the OS (macOS, Debian/Ubuntu) and:

1. **Installs tools** (prompts for each one: `y` = yes, `n` = no, `a` = accept all the rest):
   - macOS: Homebrew, then formulae and casks (`bat`, `gh`, `uv`, `colima`, `docker`, `zed`, etc.)
   - Debian/Ubuntu: `apt` packages, plus official install scripts (`uv`, `starship`, `zed`, `docker`)
2. **Sets up zsh**: installed if missing, set as the default shell, with `starship` initialized in `~/.zshrc`
3. **Links the Zed config**: symlinks from this repo to `~/.config/zed/` (`settings.json`, `keymap.json`, `tasks.json`). Any change made in Zed is reflected directly here.
4. **Zed extensions**: installed automatically on first launch via `auto_install_extensions` in `settings.json`.

Open a new terminal at the end to activate zsh and starship.

> **Notes**
> - Zed may overwrite the symlinks when saving its settings. Re-run `./install.sh` to restore them.
> - Existing config files are backed up as `.bak` before being replaced.
> - The script is idempotent: already-installed tools are skipped.

## Python project bootstrap

```bash
./new-python-project.sh <project-name> <parent-dir>
```

Creates a project with: `uv`, `typer` (CLI entrypoint), `polars`, `pydantic`, `loguru`, `ruff`, `ty`, `pytest`, `pre-commit`.

## R package bootstrap

```bash
./new-r-package.sh <package-name> <parent-dir>
```

Creates an R package with: `renv`, `devtools`, `roxygen2`, `testthat`, `dplyr`, `data.table`, `lubridate`, `rlang`, `cli`. MIT license and testthat structure configured via `usethis`.
