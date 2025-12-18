# Tool: Go programming language
# Depends on: homebrew
# Official docs: https://go.dev/doc/install
# Multi-version: https://go.dev/doc/manage-install

go_show() {
  open_url "https://go.dev/doc/install"
}

go_is_installed() {
  command -v go >/dev/null 2>&1
}

go_version() {
  if command -v go >/dev/null 2>&1; then
    go version 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

go_install() {
  # Install latest stable Go via Homebrew
  brew install go

  echo
  echo "Done. Go is installed."
  echo
  echo "Verify:"
  echo "  go version"
  echo
  echo "Multi-version support (optional):"
  echo "  Install additional versions:"
  echo "    go install golang.org/dl/go1.21.5@latest"
  echo "    go1.21.5 download"
  echo
  echo "  Use specific version:"
  echo "    go1.21.5 version"
  echo "    go1.21.5 build"
  echo
  echo "  See: https://go.dev/doc/manage-install"
  echo
}

register_tool \
  "go" \
  "Go" \
  "Install Go programming language via Homebrew + multi-version support" \
  "https://go.dev/doc/install" \
  "go_install" \
  "go_show" \
  45 \
  "homebrew" \
  "go_is_installed" \
  "go_version"
