# zed-files

Ma config Zed pour reproduire mon setup rapidement.

## Installation

```bash
git clone <repo-url> ~/zed-files
cd ~/zed-files
chmod +x install.sh
./install.sh
```

Le script crée des symlinks de ce repo vers `~/.config/zed/`, donc toute modification faite dans Zed se reflète directement ici.

## Contenu

| Fichier | Description |
|---|---|
| `settings.json` | Préférences principales (fonts, thème, langages) |
| `keymap.json` | Raccourcis clavier custom |
| `templates/.zed/debug.json` | Configs de debug Python |
| `templates/.zed/tasks.json` | Tâches Python (pytest, run, ruff) |
| `templates/pyproject.toml` | Config ruff pour un projet Python |

## Utilisation des templates Python

Copier les templates dans la racine d'un projet :

```bash
cp -r ~/zed-files/templates/.zed <mon-projet>/
cp ~/zed-files/templates/pyproject.toml <mon-projet>/   # si pas déjà un pyproject.toml
```

### Tâches disponibles (`cmd+shift+p` → `task: spawn`)

| Tâche | Description |
|---|---|
| Python: run current file | Lance le fichier courant |
| pytest: all | Tous les tests du projet |
| pytest: current file | Tests du fichier courant |
| pytest: current function | Test de la fonction sous le curseur |
| ruff: check | Lint du projet entier |

### Configs de debug disponibles

| Config | Description |
|---|---|
| Python: fichier courant | Lance `$ZED_FILE` avec debugpy |
| Python: fichier courant avec args | Idem + arguments à remplir |
| Python: module (-m) | Lance un module (`python -m ...`) |
| Python: attach (port 5678) | Attache à un process déjà lancé |

## Fonts requises

- **IBM Plex Mono** — font principale de l'éditeur
- **FiraCode Nerd Font Mono** — font du terminal

## Extensions installées

- `material-icon-theme` — icônes fichiers
- `colored-zed-icons-theme` — icônes colorées
- `html` — support HTML
- `r` — support R (avec serveur `air`)
- `rainbow-csv` — colorisation CSV
- `toml` — support TOML

## Highlights config

- Thème : One Dark / One Light (selon système)
- Keymap base : VSCode
- Python : `ty` LSP + `ruff` formatter + organise imports on save, line length 88
- R : serveur de langage `air`
- Minimap toujours visible
