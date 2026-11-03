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
  read -r -p "$1 [y/N] " answer
  [[ "$answer" =~ ^[oOyY]$ ]]
}

# ---------- Détection de l'OS ----------
case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)
    # Debian, Ubuntu et dérivés (Mint, Pop!_OS...) : tous utilisent apt
    if command -v apt >/dev/null 2>&1; then OS="debian"
    else OS="linux-other"; fi ;;
  *) OS="unknown" ;;
esac
echo "OS détecté : $OS"

# ---------- Listes d'outils (à adapter) ----------
# Astuce : `brew leaves` et `brew list --cask` sur ton Mac pour retrouver tes outils
# ---------- Listes d'outils ----------
BREW_FORMULAE=(bat btop colima gh mole node rtk starship tree typst uv glab npm)
BREW_CASKS=(basictex bruno r-app zed)

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

# ---------- zsh + Oh My Zsh + starship ----------
install_zsh() {
  command -v zsh >/dev/null 2>&1 && return 0
  # macOS l'a déjà de base ; sur apt on propose de l'installer
  if [ "$OS" = "debian" ] && confirm "zsh n'est pas installé. L'installer via apt ?"; then
    sudo apt install -y zsh
  fi
  command -v zsh >/dev/null 2>&1 || { echo "  ! zsh introuvable, installe-le manuellement."; return 1; }
}

set_default_shell() {
  if [ "$(basename "$SHELL")" = "zsh" ]; then
    echo "  ✓ zsh est déjà le shell par défaut"
    return
  fi
  confirm "Définir zsh comme shell par défaut ?" || return 0
  local zsh_path
  zsh_path="$(command -v zsh)"
  grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$zsh_path"
  echo "  → Effectif à la prochaine connexion (ouvre un nouveau terminal)."
}

install_ohmyzsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  ✓ Oh My Zsh déjà installé"
    return
  fi
  confirm "Installer Oh My Zsh ?" || return 0
  # L'installeur écrit un ~/.zshrc neuf et sauvegarde l'ancien : on le ré-ajoute
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  if [ -f "$HOME/.zshrc.pre-oh-my-zsh" ]; then
    { echo; echo "# --- ancien ~/.zshrc ---"; cat "$HOME/.zshrc.pre-oh-my-zsh"; } >> "$HOME/.zshrc"
  fi
}

configure_zshrc() {
  touch "$HOME/.zshrc"

  if [ "$OS" = "debian" ] && ! grep -q '.local/bin' "$HOME/.zshrc"; then
    # uv, bat (symlink batcat) et d'autres outils s'installent ici
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  fi

  if ! command -v starship >/dev/null 2>&1; then
    echo "  ! starship n'est pas installé, ligne non ajoutée à ~/.zshrc."
  elif grep -q 'starship init zsh' "$HOME/.zshrc"; then
    echo "  ✓ starship déjà configuré dans ~/.zshrc"
  else
    # starship doit rester en toute fin de fichier
    printf '\n# Starship prompt (doit rester en fin de fichier)\neval "$(starship init zsh)"\n' >> "$HOME/.zshrc"
    echo "  ✓ starship ajouté à ~/.zshrc"
  fi
}

setup_zsh() {
  echo ""
  echo "Configuration de zsh..."
  install_zsh || return 0
  set_default_shell
  install_ohmyzsh
  configure_zshrc
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
