homebrew_show() { open_url "https://brew.sh/"; }

homebrew_is_installed() {
  command -v brew >/dev/null 2>&1
}

homebrew_version() {
  if command -v brew >/dev/null 2>&1; then
    brew --version 2>/dev/null | head -n 1
  else
    echo "unknown"
  fi
}

homebrew_install() {
  if homebrew_is_installed; then
    echo "Homebrew already installed: $(command -v brew)"
    echo "The official Homebrew installer is idempotent and handles existing installations."
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  brew --version >/dev/null 2>&1 || true
}

register_tool \
  "homebrew" \
  "Homebrew" \
  "Install Homebrew package manager" \
  "https://brew.sh/" \
  "homebrew_install" \
  "homebrew_show" \
  0 \
  "" \
  "homebrew_is_installed" \
  "homebrew_version"
