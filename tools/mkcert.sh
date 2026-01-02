# Tool: mkcert - Simple tool for making locally-trusted development certificates
# Depends on: homebrew
# Links: https://github.com/FiloSottile/mkcert

mkcert_show() {
  open_url "https://github.com/FiloSottile/mkcert"
}

mkcert_is_installed() {
  command -v mkcert >/dev/null 2>&1
}

mkcert_version() {
  if command -v mkcert >/dev/null 2>&1; then
    mkcert -version 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^v//' || echo "unknown"
  else
    echo "unknown"
  fi
}

mkcert_install() {
  # Install nss (required for Firefox support)
  brew install nss

  # Install mkcert via Homebrew
  brew install mkcert

  # Install local CA
  echo ""
  echo "Installing local CA (Certificate Authority)..."
  mkcert -install

  echo ""
  echo "Done. mkcert installed successfully."
  echo ""
  echo "Usage:"
  echo "  Create certificate:  mkcert example.com '*.example.com' localhost 127.0.0.1"
  echo "  Install local CA:    mkcert -install"
  echo "  Uninstall local CA:  mkcert -uninstall"
  echo ""
  echo "The local CA is now installed in your system trust store."
  echo "Certificates created with mkcert will be trusted by your browser and tools."
  echo ""
  echo "Verify with: mkcert -version"
}

register_tool \
  "mkcert" \
  "mkcert" \
  "Install mkcert for locally-trusted development certificates via Homebrew" \
  "https://github.com/FiloSottile/mkcert" \
  "mkcert_install" \
  "mkcert_show" \
  55 \
  "homebrew" \
  "mkcert_is_installed" \
  "mkcert_version"
