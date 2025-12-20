# Tool: Docker CLI (docker)
# Purpose: Install the docker client binary (works with Colima's Docker daemon)
# Depends on: homebrew

gh_cli_show() {
  open_url "https://formulae.brew.sh/formula/gh"
}

gh_cli_is_installed() {
  command -v gh >/dev/null 2>&1
}

gh_cli_version() {
  if command -v gh >/dev/null 2>&1; then
    docker --version 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

gh_cli_install() {
  # Installs the gh cli
  brew install gh

  echo
  echo "Tip (Github CLI):"
  echo "  - Start runtime: gh <command>"
  echo "  - Test: gh --version"
  echo
}

register_tool \
  "gh-cli" \
  "Github CLI" \
  "Install github cli binary" \
  "https://formulae.brew.sh/formula/gh" \
  "gh_cli_install" \
  "gh_cli_show" \
  35 \
  "homebrew" \
  "gh_cli_is_installed" \
  "gh_cli_version"
