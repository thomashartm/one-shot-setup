claude_show() { open_url "https://code.claude.com/docs/en/setup"; }

claude_is_installed() {
  command -v claude >/dev/null 2>&1
}

claude_version() {
  if command -v claude >/dev/null 2>&1; then
    claude --version 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

claude_install() {
  curl -fsSL https://claude.ai/install.sh | bash
}

register_tool \
  "claude" \
  "Claude" \
  "Install Claude CLI via official installer" \
  "https://claude.ai/" \
  "claude_install" \
  "claude_show" \
  30 \
  "homebrew" \
  "claude_is_installed" \
  "claude_version"
