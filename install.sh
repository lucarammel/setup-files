#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZED_CONFIG="$HOME/.config/zed"

# ---------- Options ----------
ASSUME_YES=false
[[ "$1" == "-y" || "$1" == "--yes" ]] && ASSUME_YES=true

confirm() {
  # usage: confirm "Question ?"
  $ASSUME_YES && return 0
  read -r -p "$1 [o/N] " answer
  [[ "$answer" =~ ^[oOyY]$ ]]
}

# ---------- Détection de l'OS ----------
case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)
    if command -v apt >/dev/null 2>&1; then OS="debian"
    else OS="linux-other"; fi ;;
  *) OS="unknown" ;;
esac
echo "OS détecté : $OS"

# ---------- Listes d'outils (à adapter) ----------
# Astuce : `brew leaves` et `brew list --cask` sur ton Mac pour retrouver tes outils
# ---------- Listes d'outils ----------
BREW_FORMULAE=(bat btop colima gh mole node rtk starship tree typst uv glab)
BREW_CASKS=(basictex bruno maccy r-app stats zed)

# Paquets disponibles directement dans apt
APT_PACKAGES=(git curl build-essential bat btop gh nodejs npm tree r-base texlive-latex-base)

# ---------- Installation des outils ----------
install_tools_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    if confirm "Homebrew n'est pas installé. L'installer ?"; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # Ajoute brew au PATH pour la session (Apple Silicon / Intel)
      [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
      [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
    else
      echo "Homebrew ignoré, installation des outils annulée."
      return
    fi
  fi

  echo "Formulae : ${BREW_FORMULAE[*]}"
  if confirm "Installer ces formulae via brew ?"; then
    for pkg in "${BREW_FORMULAE[@]}"; do
      brew list "$pkg" >/dev/null 2>&1 && echo "  ✓ $pkg déjà installé" || brew install "$pkg"
    done
  fi

  echo "Applications (casks) : ${BREW_CASKS[*]}"
  if confirm "Installer ces applications via brew --cask ?"; then
    for cask in "${BREW_CASKS[@]}"; do
      brew list --cask "$cask" >/dev/null 2>&1 && echo "  ✓ $cask déjà installé" || brew install --cask "$cask"
    done
  fi
}

install_tools_debian() {
  echo "Paquets apt : ${APT_PACKAGES[*]}"
  if confirm "Installer ces paquets via apt (sudo requis) ?"; then
    sudo apt update
    for pkg in "${APT_PACKAGES[@]}"; do
      dpkg -s "$pkg" >/dev/null 2>&1 && echo "  ✓ $pkg déjà installé" || sudo apt install -y "$pkg"
    done
    # Sur Debian/Ubuntu, bat s'installe sous le nom batcat
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
  fi

  # Outils hors apt, via leurs scripts officiels
  if ! command -v uv >/dev/null 2>&1 && confirm "Installer uv (astral.sh) ?"; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi

  if ! command -v starship >/dev/null 2>&1 && confirm "Installer starship ?"; then
    curl -sS https://starship.rs/install.sh | sh
  fi

  if ! command -v zed >/dev/null 2>&1 && confirm "Installer Zed (zed.dev) ?"; then
    curl -f https://zed.dev/install.sh | sh
  fi

  if ! command -v typst >/dev/null 2>&1 && command -v snap >/dev/null 2>&1 \
     && confirm "Installer typst (snap) ?"; then
    sudo snap install typst
  fi

  if ! command -v bruno >/dev/null 2>&1 && command -v snap >/dev/null 2>&1 \
     && confirm "Installer Bruno (snap) ?"; then
    sudo snap install bruno
  fi
}

echo ""
case "$OS" in
  macos)  install_tools_macos ;;
  debian) install_tools_debian ;;
  *)      echo "OS non supporté pour l'installation automatique des outils, étape ignorée." ;;
esac

# ---------- zsh + starship ----------
setup_zsh() {
  echo ""
  echo "Configuration de zsh..."

  # 1. Installer zsh si absent (macOS l'a déjà de base)
  if ! command -v zsh >/dev/null 2>&1; then
    case "$OS" in
      debian)
        if confirm "zsh n'est pas installé. L'installer via apt ?"; then
          sudo apt install -y zsh
        fi ;;
      *) echo "  ! zsh introuvable, installe-le manuellement."; return ;;
    esac
  fi
  command -v zsh >/dev/null 2>&1 || return

  # 2. Le définir comme shell par défaut
  if [ "$(basename "$SHELL")" != "zsh" ]; then
    if confirm "Définir zsh comme shell par défaut ?"; then
      ZSH_PATH="$(command -v zsh)"
      grep -qx "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
      chsh -s "$ZSH_PATH"
      echo "  → Effectif à la prochaine connexion (ouvre un nouveau terminal)."
    fi
  else
    echo "  ✓ zsh est déjà le shell par défaut"
  fi

  # 3. ~/.zshrc : PATH, puis starship en dernier
  touch "$HOME/.zshrc"

  if [ "$OS" = "debian" ] && ! grep -q '.local/bin' "$HOME/.zshrc"; then
    # uv, bat (symlink batcat) et d'autres outils s'installent ici
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  fi

  if command -v starship >/dev/null 2>&1; then
    if ! grep -q 'starship init zsh' "$HOME/.zshrc"; then
      # Ligne vide au cas où le fichier ne finit pas par un retour à la ligne
      printf '\n# Starship prompt (doit rester en fin de fichier)\neval "$(starship init zsh)"\n' >> "$HOME/.zshrc"
      echo "  ✓ starship ajouté à ~/.zshrc"
    else
      echo "  ✓ starship déjà configuré dans ~/.zshrc"
    fi
  else
    echo "  ! starship n'est pas installé, ligne non ajoutée à ~/.zshrc."
  fi
}

setup_zsh

# ---------- Config Zed ----------
echo ""
echo "Setting up Zed config from $REPO_DIR..."
mkdir -p "$ZED_CONFIG"

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

chmod +x "$REPO_DIR/new-python-project.sh"
chmod +x "$REPO_DIR/new-r-package.sh"

echo ""
echo "Open a new terminal to take all installations into account."
echo ""
echo "Done. Open Zed : extensions will be automatically installed"
echo "(via auto_install_extensions in settings.json)."
echo ""
echo "To create a new Python project:"
echo "  ~/setup-files/new-python-project.sh <project-name> <root-folder>"
echo ""
echo "To create a new R package:"
echo "  ~/setup-files/new-r-package.sh <package-name> <root-folder>"
