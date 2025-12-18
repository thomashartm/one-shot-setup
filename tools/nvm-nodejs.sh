# Tool: Node.js stack via nvm (nvm + latest LTS node + npm)
# Depends on: homebrew

nodejs_show() {
  open_url "https://github.com/nvm-sh/nvm"
}

_nodejs_brew_bin() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    echo "/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    echo "/usr/local/bin/brew"
  elif command -v brew >/dev/null 2>&1; then
    command -v brew
  else
    return 1
  fi
}

_nodejs_ensure_nvm_config() {
  local zshrc="${HOME}/.zshrc"
  local nvm_dir="${HOME}/.nvm"
  mkdir -p "$nvm_dir"
  touch "$zshrc"

  # Check if complete config exists
  if grep -Fq "# OneShotSetup: nvm (Node Version Manager)" "$zshrc" && \
     grep -Fq 'export NVM_DIR="$HOME/.nvm"' "$zshrc" && \
     grep -Fq 'NVM_SH="$(brew --prefix nvm)/nvm.sh"' "$zshrc"; then
    return 0
  fi

  # Remove any incomplete/old config block
  if grep -Fq "# OneShotSetup: nvm (Node Version Manager)" "$zshrc"; then
    echo "Removing incomplete nvm config from $zshrc"
    # Create temp file without the nvm block
    local tmp_file
    tmp_file="$(mktemp)"
    awk '
      /# OneShotSetup: nvm \(Node Version Manager\)/ { skip=1; next }
      skip && /^[[:space:]]*$/ { skip=0; next }
      skip && /^[[:space:]]*#/ { next }
      skip && /^[[:space:]]*(export|if|then|fi|\[)/ { next }
      { if (!skip) print }
    ' "$zshrc" > "$tmp_file"
    mv "$tmp_file" "$zshrc"
  fi

  {
    echo
    echo "# OneShotSetup: nvm (Node Version Manager)"
    echo 'export NVM_DIR="$HOME/.nvm"'
    echo '# Load nvm from Homebrew (works for both /opt/homebrew and /usr/local once shellenv is loaded via ~/.zprofile)'
    echo 'if command -v brew >/dev/null 2>&1; then'
    echo '  NVM_SH="$(brew --prefix nvm)/nvm.sh"'
    echo '  [ -s "$NVM_SH" ] && . "$NVM_SH"'
    echo 'fi'
  } >> "$zshrc"

  echo "Added nvm init to $zshrc"
}

_nodejs_source_nvm_for_script() {
  local brew_bin
  brew_bin="$(_nodejs_brew_bin)" || die "Homebrew not found on PATH. Open a new shell or ensure ~/.zprofile loads brew shellenv."

  # Source nvm for *this* install script run
  local nvm_sh
  nvm_sh="$("$brew_bin" --prefix nvm 2>/dev/null)/nvm.sh"
  [[ -s "$nvm_sh" ]] || die "nvm.sh not found. Is nvm installed via Homebrew?"

  export NVM_DIR="${HOME}/.nvm"
  # shellcheck disable=SC1090
  . "$nvm_sh" >/dev/null 2>&1
}

_nodejs_install_latest_node() {
  _nodejs_source_nvm_for_script

  # Install latest LTS (avoids current/odd releases)
  nvm install --lts
  nvm alias default lts/*
  nvm use default >/dev/null 2>&1 || true
}

nodejs_is_installed() {
  # Don't explode if brew isn't available in non-interactive contexts
  command -v brew >/dev/null 2>&1 || return 1

  local nvm_sh
  nvm_sh="$(brew --prefix nvm 2>/dev/null)/nvm.sh"
  [[ -s "$nvm_sh" ]] || return 1

  export NVM_DIR="${HOME}/.nvm"
  # shellcheck disable=SC1090
  . "$nvm_sh" >/dev/null 2>&1 || true

  command -v nvm  >/dev/null 2>&1 || return 1
  command -v node >/dev/null 2>&1 || return 1
  command -v npm  >/dev/null 2>&1 || return 1
  return 0
}

nodejs_version() {
  local nvm_v="unknown" node_v="unknown" npm_v="unknown"

  if command -v brew >/dev/null 2>&1; then
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
  fi

  echo "nvm=${nvm_v}, node=${node_v}, npm=${npm_v}"
}

nodejs_install() {
  # Install nvm via Homebrew
  brew install nvm

  # Configure interactive loading of nvm
  _nodejs_ensure_nvm_config

  echo "Installing latest Node via nvm..."
  _nodejs_install_latest_node

  echo
  echo "Done."
  echo "Open a NEW terminal (recommended) or run:"
  echo "  source ~/.zprofile"
  echo "  source ~/.zshrc"
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
