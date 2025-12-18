# Tool: uv (Python package & project manager) - OFFICIAL installer
# Installs via Astral standalone installer: curl -LsSf https://astral.sh/uv/install.sh | sh :contentReference[oaicite:1]{index=1}

uv_show() {
  open_url "https://docs.astral.sh/uv/getting-started/installation/"
}

uv_is_installed() {
  command -v uv >/dev/null 2>&1 || [[ -x "${HOME}/.local/bin/uv" ]]
}

uv_version() {
  if command -v uv >/dev/null 2>&1; then
    uv --version 2>/dev/null || echo "unknown"
  elif [[ -x "${HOME}/.local/bin/uv" ]]; then
    "${HOME}/.local/bin/uv" --version 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

_uv_ensure_local_bin_on_path() {
  # Official uninstall instructions reference ~/.local/bin/uv, so ensure ~/.local/bin is on PATH. :contentReference[oaicite:2]{index=2}
  local zshenv="${HOME}/.zshenv"
  local localbin="${HOME}/.local/bin"

  mkdir -p "$localbin"
  touch "$zshenv"

  # Check if complete config exists
  if grep -Fq "# OneShotSetup: ensure uv install location is on PATH" "$zshenv" && \
     grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$zshenv"; then
    return 0
  fi

  # Remove any incomplete/old config block
  if grep -Fq "# OneShotSetup: ensure uv install location is on PATH" "$zshenv"; then
    echo "Removing incomplete uv PATH config from $zshenv"
    local tmp_file
    tmp_file="$(mktemp)"
    awk '
      /# OneShotSetup: ensure uv install location is on PATH/ { skip=1; next }
      skip && /^[[:space:]]*$/ { skip=0; next }
      skip && /^[[:space:]]*(export|PATH=)/ { next }
      { if (!skip) print }
    ' "$zshenv" > "$tmp_file"
    mv "$tmp_file" "$zshenv"
  fi

  {
    echo
    echo "# OneShotSetup: ensure uv install location is on PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
  } >> "$zshenv"

  echo "Hinweis: ~/.local/bin wurde zu deinem PATH in ~/.zshenv hinzugefügt."
  echo "Öffne ein neues Terminal oder führe aus: source ~/.zshenv"
}

uv_install() {
  # Official standalone installer :contentReference[oaicite:3]{index=3}
  curl -LsSf https://astral.sh/uv/install.sh | sh

  _uv_ensure_local_bin_on_path

  echo
  echo "Verify:"
  echo "  uv --version"
  echo
  echo "Optional (Updates, wenn via Standalone-Installer installiert):"
  echo "  uv self update"
  echo
}

register_tool \
  "uv" \
  "uv" \
  "Install uv via official Astral standalone installer" \
  "https://docs.astral.sh/uv/getting-started/installation/" \
  "uv_install" \
  "uv_show" \
  45 \
  "" \
  "uv_is_installed" \
  "uv_version"
