# Tool: opencode - CLI tool to open files and directories in your editor
# Depends on: homebrew
# Links: https://github.com/opencode/opencode

opencode_show() {
  open_url "https://formulae.brew.sh/formula/opencode"
}

opencode_is_installed() {
  command -v opencode >/dev/null 2>&1
}

opencode_version() {
  if command -v opencode >/dev/null 2>&1; then
    opencode --version 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

opencode_install() {
  # Install opencode via Homebrew
  brew install opencode

  echo
  echo "Done. opencode installed successfully."
  echo
  echo "Usage:"
  echo "  Open current directory:  opencode ."
  echo "  Open specific file:      opencode path/to/file"
  echo "  Open directory:          opencode path/to/directory"
  echo
  echo "Verify with: opencode --version"
  echo
}

register_tool \
  "opencode" \
  "opencode" \
  "Install opencode CLI tool via Homebrew" \
  "https://formulae.brew.sh/formula/opencode" \
  "opencode_install" \
  "opencode_show" \
  55 \
  "homebrew" \
  "opencode_is_installed" \
  "opencode_version"
