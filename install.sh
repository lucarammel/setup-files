#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZED_CONFIG="$HOME/.config/zed"

echo "Setting up Zed config from $REPO_DIR..."

# Create config dir if needed
mkdir -p "$ZED_CONFIG"

# Symlink config files
for file in settings.json keymap.json tasks.json; do
  target="$ZED_CONFIG/$file"
  source="$REPO_DIR/$file"

  if [ -f "$target" ] && [ ! -L "$target" ]; then
    echo "Backing up existing $file → $file.bak"
    mv "$target" "$target.bak"
  fi

  ln -sf "$source" "$target"
  echo "Linked $file"
done

# Install extensions
extensions=(
  "material-icon-theme"
  "r"
  "rainbow-csv"
  "toml"
  "colored-zed-icons-theme"
)

echo ""
echo "Installing extensions..."
for ext in "${extensions[@]}"; do
  echo "  zed --install-extension $ext"
  zed --install-extension "$ext" 2>/dev/null || echo "  (install manually if Zed is not in PATH)"
done

chmod +x "$REPO_DIR/new-python-project.sh"
chmod +x "$REPO_DIR/new-r-package.sh"

echo ""
echo "Done. Open Zed and your config will be active."
echo ""
echo "Pour créer un nouveau projet Python :"
echo "  ~/zed-files/new-python-project.sh <nom-projet> <dossier-parent>"
echo ""
echo "Pour créer un package R :"
echo "  ~/zed-files/new-r-package.sh <nom-package> <dossier-parent>"
