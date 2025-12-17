# Tool: Node.js stack via nvm (nvm + latest node + npm)
# Depends on: homebrew
# - Installs nvm via Homebrew
# - Configures nvm in ~/.zshenv
# - Uses nvm to install the latest Node version (npm included with Node)

nodejs_show() {
  open_url "https://github.com/nvm-sh/nvm"
}

nodejs_is_installed() {
  # nvm installed via brew => nvm.sh exists
  local nvm_sh
  nvm_sh="$(brew --prefix nvm 2>/dev/null)/nvm.sh"
  [[ -s "$nvm_sh" ]] || return 1

  # Latest node installed via nvm => node exists after sourcing nvm
  export NVM_DIR="${HOME}/.nvm"
  # shellcheck disable=SC1090
  . "$nvm_sh" >/dev/null 2>&1 || true

  command -v nvm >/dev/null 2>&1 || return 1
  command -v node >/dev/null 2>&1 || return 1
  command -v npm  >/dev/null 2>&1 || return 1

  return 0
}

nodejs_version() {
  local nvm_v node_v npm_v
  nvm_v="unknown"
  node_v="unknown"
  npm_v="unknown"

  local nvm_sh
  nvm_sh="$(brew --prefix nvm 2>/dev/null)/nvm.sh"
  if [[ -s "$nvm_sh" ]]; then
    export NVM_DIR="${HOME}/.nvm"
    # shellcheck disable=SC1090
    . "$nvm_sh" >/dev/null 2>&1 || true
    if type nvm >/dev/null 2>&1; then
      nvm_v="$(nvm --version 2>/dev/null || echo "unknown")"
      node_v="$(node -v 2>/dev/null || echo "unknown")"
      npm_v="$(npm -v 2>/dev/null || echo "unknown")"
    fi
  fi

  echo "nvm=${nvm_v}, node=${node_v}, npm=${npm_v}"
}

_nodejs_ensure_nvm_config() {
  local zshenv="${HOME}/.zshenv"
  local nvm_dir="${HOME}/.nvm"

  mkdir -p "$nvm_dir"
  touch "$zshenv"

  # Avoid duplicates
  if grep -Fq 'export NVM_DIR="$HOME/.nvm"' "$zshenv"; then
    return 0
  fi

  {
    echo
    echo "# OneShotSetup: nvm (Node Version Manager)"
    echo 'export NVM_DIR="$HOME/.nvm"'
    echo '[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"'
  } >> "$zshenv"

  echo "Added nvm init to $zshenv"
}

_nodejs_install_latest_node() {
  local nvm_sh
  nvm_sh="$(brew --prefix nvm 2>/dev/null)/nvm.sh"
  [[ -s "$nvm_sh" ]] || die "nvm.sh not found after installing nvm."

  export NVM_DIR="${HOME}/.nvm"
  # shellcheck disable=SC1090
  . "$nvm_sh" >/dev/null 2>&1

  # Install + use "node" (latest)
  nvm install node
  nvm alias default node
  nvm use default >/dev/null 2>&1 || true
}

nodejs_install() {
  # Install nvm via Homebrew
  brew install nvm

  _nodejs_ensure_nvm_config

  echo "Installing latest Node via nvm..."
  _nodejs_install_latest_node

  echo
  echo "Done."
  echo "Open a new terminal or run: source ~/.zshenv"
  echo "Verify:"
  echo "  nvm --version"
  echo "  node -v"
  echo "  npm -v"
  echo
}

register_tool \
  "nvm" \
  "NVM and Node.js" \
  "Install nvm via Homebrew and install latest Node (managed by nvm)" \
  "https://github.com/nvm-sh/nvm" \
  "nodejs_install" \
  "nodejs_show" \
  45 \
  "homebrew" \
  "nodejs_is_installed" \
  "nodejs_version"
