# setup-files

Ma config Zed + scripts de bootstrap de projets.

## Installation

```bash
git clone <repo-url> ~/setup-files
cd ~/setup-files
./install.sh
```

Crée des symlinks de ce repo vers `~/.config/zed/`. Toute modif faite dans Zed se reflète directement ici.

> **Note** : Zed peut écraser les symlinks en sauvegardant ses settings. Relancer `./install.sh` pour les restaurer.


## Bootstrap projet Python

```bash
./new-python-project.sh <nom-projet> <dossier-parent>
```

Crée un projet avec : `uv`, `typer` (CLI entrypoint), `polars`, `pydantic`, `loguru`, `ruff`, `ty`, `pytest`, `pre-commit`.

## Bootstrap package R

```bash
./new-r-package.sh <nom-package> <dossier-parent>
```

Crée un package R avec : `renv`, `devtools`, `roxygen2`, `testthat`, `dplyr`, `data.table`, `lubridate`, `rlang`, `cli`. Licence MIT et structure testthat configurées via `usethis`.
