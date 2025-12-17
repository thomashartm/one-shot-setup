# Tool: Docker CLI (docker)
# Purpose: Install the docker client binary (works with Colima's Docker daemon)
# Depends on: homebrew

docker_cli_show() {
  open_url "https://formulae.brew.sh/formula/docker"
}

docker_cli_is_installed() {
  command -v docker >/dev/null 2>&1
}

docker_cli_version() {
  if command -v docker >/dev/null 2>&1; then
    docker --version 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

docker_cli_install() {
  # Installs the Docker client only (no Docker Desktop).
  brew install docker

  echo
  echo "Tip (Colima):"
  echo "  - Start runtime: colima start"
  echo "  - Test: docker version"
  echo
}

register_tool \
  "docker-cli" \
  "Docker CLI" \
  "Install docker client binary (for use with Colima)" \
  "https://formulae.brew.sh/formula/docker" \
  "docker_cli_install" \
  "docker_cli_show" \
  35 \
  "homebrew" \
  "docker_cli_is_installed" \
  "docker_cli_version"
