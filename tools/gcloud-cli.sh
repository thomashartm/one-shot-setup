# Tool: Google Cloud CLI (gcloud)
# Depends on: homebrew
# Installs via Homebrew cask: gcloud-cli (former token: google-cloud-sdk) :contentReference[oaicite:1]{index=1}

gcloud_cli_show() {
  open_url "https://cloud.google.com/sdk/docs/install"
}

gcloud_cli_is_installed() {
  command -v gcloud >/dev/null 2>&1
}

gcloud_cli_version() {
  if command -v gcloud >/dev/null 2>&1; then
    # First line usually contains the main version label.
    gcloud version 2>/dev/null | head -n 1 || echo "unknown"
  else
    echo "unknown"
  fi
}

_gcloud_cli_ensure_path_for_components() {
  # Homebrew notes: to use additional binary components installed via gcloud,
  # add $HOMEBREW_PREFIX/share/google-cloud-sdk/bin to PATH. :contentReference[oaicite:2]{index=2}
  local zshenv="${HOME}/.zshenv"
  local brew_prefix
  brew_prefix="$(brew --prefix 2>/dev/null || true)"
  [[ -n "$brew_prefix" ]] || return 0

  local path_line="export PATH=${brew_prefix}/share/google-cloud-sdk/bin:\"\$PATH\""

  touch "$zshenv"

  # Check if complete config exists
  if grep -Fq "# OneShotSetup: Google Cloud CLI (gcloud)" "$zshenv" && \
     grep -Fq "${brew_prefix}/share/google-cloud-sdk/bin" "$zshenv"; then
    return 0
  fi

  # Remove any incomplete/old config block
  if grep -Fq "# OneShotSetup: Google Cloud CLI (gcloud)" "$zshenv"; then
    echo "Removing incomplete gcloud PATH config from $zshenv"
    local tmp_file
    tmp_file="$(mktemp)"
    awk '
      /# OneShotSetup: Google Cloud CLI \(gcloud\)/ { skip=1; next }
      skip && /^[[:space:]]*$/ { skip=0; next }
      skip && /^[[:space:]]*(export|PATH=)/ { next }
      { if (!skip) print }
    ' "$zshenv" > "$tmp_file"
    mv "$tmp_file" "$zshenv"
  fi

  {
    echo
    echo "# OneShotSetup: Google Cloud CLI (gcloud) - PATH for gcloud-installed components"
    echo "$path_line"
  } >> "$zshenv"

  echo "Added to $zshenv:"
  echo "  $path_line"
  echo "Open a new terminal or run: source ~/.zshenv"
}

gcloud_cli_install() {
  # Install command from Homebrew Formulae page. :contentReference[oaicite:3]{index=3}
  brew install --cask gcloud-cli

  _gcloud_cli_ensure_path_for_components

  echo
  echo "Next steps:"
  echo "  - Authenticate / configure: gcloud init"
  echo "  - (Optional) Login only:     gcloud auth login"
  echo
}

register_tool \
  "gcloud-cli" \
  "Google Cloud CLI" \
  "Install gcloud CLI via Homebrew + PATH for components" \
  "https://cloud.google.com/sdk/docs/install" \
  "gcloud_cli_install" \
  "gcloud_cli_show" \
  50 \
  "homebrew" \
  "gcloud_cli_is_installed" \
  "gcloud_cli_version"
