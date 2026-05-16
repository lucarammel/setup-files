#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <nom-du-projet> <dossier-parent>"
  exit 1
fi

PROJECT_NAME="$1"
PROJECT_NAME_SNAKE=$(echo "$PROJECT_NAME" | tr '-' '_')
PARENT_DIR="$2"
PROJECT_DIR="$PARENT_DIR/$PROJECT_NAME"

echo "Création de $PROJECT_DIR..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"


# pyproject.toml
cp "$REPO_DIR/templates/pyproject.toml" .
sed -i '' "s/mon-projet/$PROJECT_NAME/g" pyproject.toml
sed -i '' "s/mon_projet/$PROJECT_NAME_SNAKE/g" pyproject.toml

# Configs
cp "$REPO_DIR/templates/.gitignore" .
cp "$REPO_DIR/templates/.pre-commit-config.yaml" .
cp "$REPO_DIR/templates/.python-version" .
cp "$REPO_DIR/templates/README.md" .
sed -i '' "s/mon-projet/$PROJECT_NAME/g" README.md

# Zed
cp -r "$REPO_DIR/templates/.zed" .

# Fichiers de départ
mkdir -p "$PROJECT_NAME_SNAKE"
touch "$PROJECT_NAME_SNAKE/__init__.py"

cat > "$PROJECT_NAME_SNAKE/main.py" <<EOF
import typer

app = typer.Typer()


@app.command()
def main() -> None:
    pass


if __name__ == "__main__":
    app()
EOF

# Git
git init

# Venv + dépendances
echo "Initialisation de l'environnement uv..."
uv venv
uv add typer polars pydantic loguru
uv add pytest pytest-cov ruff ty pre-commit jupyter ipython --dev

# Pre-commit
uv run pre-commit install

git add .
git commit -m "init: $PROJECT_NAME"

echo ""
echo "Projet créé : $PROJECT_DIR"
echo ""
echo "  uv run python $PROJECT_NAME_SNAKE/main.py"
echo "  uv run pytest"
echo "  uv run ruff check ."
echo "  uv run ty check ."
echo "  uv add <package>"
echo "  zed ."
