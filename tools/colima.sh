# Tool: Colima (Containers on Lima) + AWS SAM adaptation
# Depends on: homebrew
# AWS SAM note: SAM local checks for DOCKER_HOST; we set it to Colima's docker.sock. :contentReference[oaicite:1]{index=1}

colima_show() {
  open_url "https://github.com/abiosoft/colima"
}

colima_is_installed() {
  command -v colima >/dev/null 2>&1
}

colima_version() {
  if command -v colima >/dev/null 2>&1; then
    colima version 2>/dev/null | head -n 1 || echo "unknown"
  else
    echo "unknown"
  fi
}

_colima_detect_socket_path() {
  # Your gist uses $HOME/.colima/docker.sock; newer setups may also use $HOME/.colima/default/docker.sock.
  # Prefer the gist path if it exists, otherwise fall back to default profile path.
  local p1="${HOME}/.colima/docker.sock"
  local p2="${HOME}/.colima/default/docker.sock"

  if [[ -S "$p1" ]]; then
    echo "$p1"
  elif [[ -S "$p2" ]]; then
    echo "$p2"
  else
    # Default to gist path (it will exist after colima start on some setups)
    echo "$p1"
  fi
}

_colima_ensure_docker_host_in_zshenv() {
  local socket_path="$1"
  local zshenv="${HOME}/.zshenv"
  local desired="export DOCKER_HOST=\"unix://${socket_path}\""

  touch "$zshenv"

  # If any DOCKER_HOST is already set in .zshenv, don't duplicate; just inform.
  if grep -Eq '^[[:space:]]*export[[:space:]]+DOCKER_HOST=' "$zshenv"; then
    echo "Found existing DOCKER_HOST export in $zshenv (leaving as-is)."
    echo "Wanted for Colima/SAM: $desired"
    return 0
  fi

  {
    echo
    echo "# OneShotSetup: AWS SAM local via Colima (DOCKER_HOST -> Colima docker.sock)"
    echo "$desired"
  } >> "$zshenv"

  echo "Added DOCKER_HOST export to $zshenv:"
  echo "  $desired"
}

colima_install() {
  # Install Colima via Homebrew (official docs) :contentReference[oaicite:2]{index=2}
  brew install colima

  # Optional but commonly needed: Docker CLI client (SAM itself may not need it, but dev workflows do)
  if ! command -v docker >/dev/null 2>&1; then
    echo
    echo "Note: 'docker' CLI not found. If you want the Docker client:"
    echo "  brew install docker docker-compose"
    echo
  fi

  # Start Colima so the docker socket exists
  echo "Starting Colima (if not already running)..."
  colima start || true

  # Detect socket path and persist DOCKER_HOST for AWS SAM usage :contentReference[oaicite:3]{index=3}
  local socket_path
  socket_path="$(_colima_detect_socket_path)"
  _colima_ensure_docker_host_in_zshenv "$socket_path"

  echo
  echo "Next steps (AWS SAM):"
  echo "  1) Open a new terminal, or run: source ~/.zshenv"   # :contentReference[oaicite:4]{index=4}
  echo "  2) Rebuild using containers: sam build -u"          # :contentReference[oaicite:5]{index=5}
  echo

  # Helpful: show current runtime socket status
  if [[ -S "$socket_path" ]]; then
    echo "Colima docker socket detected at: $socket_path"
  else
    echo "Warning: docker socket not detected yet at: $socket_path"
    echo "Try: colima status  (and then re-run ./start.sh install colima if needed)"
  fi
}

register_tool \
  "colima" \
  "Colima" \
  "Local container runtime (Docker alternative) + AWS SAM DOCKER_HOST setup" \
  "https://github.com/abiosoft/colima" \
  "colima_install" \
  "colima_show" \
  40 \
  "homebrew" \
  "colima_is_installed" \
  "colima_version"
