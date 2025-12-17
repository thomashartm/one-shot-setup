# OneShotSetup Tool Template
#
# Copy this file:
#   cp tools/_template.sh tools/<yourtool>.sh
#
# Then replace placeholders:
#   TOOL_ID, TOOL_NAME, TOOL_DESC, TOOL_URL
#   <tool>_install / <tool>_show / <tool>_is_installed / <tool>_version
#   priority + deps
#
# Notes:
# - This file is sourced by start.sh (not executed directly).
# - Keep it Bash 3.2 compatible (macOS default).

# ---- Required metadata ----
# ID should be lowercase, no spaces, use hyphens if needed (e.g. "oh-my-zsh")
TOOL_ID="your-tool-id"
TOOL_NAME="Your Tool Name"
TOOL_DESC="What this tool installs/configures"
TOOL_URL="https://example.com/install"

# ---- Optional: dependencies + priority ----
# Lower priority = earlier install (homebrew is typically 0)
TOOL_PRIORITY=50
# Space-separated list of tool IDs
TOOL_DEPS="homebrew"

# ---- Show (opens install/info page) ----
your_tool_show() {
  # open_url is provided by start.sh
  open_url "$TOOL_URL"
}

# ---- Detect installation ----
your_tool_is_installed() {
  # Return 0 if installed, non-zero if not.
  # Examples:
  #   command -v yourtool >/dev/null 2>&1
  #   [[ -d "${HOME}/.yourtool" ]]
  command -v yourtool >/dev/null 2>&1
}

# ---- Version ----
your_tool_version() {
  # Echo a human-readable version string.
  # Keep it resilient (do not fail if version command errors).
  if command -v yourtool >/dev/null 2>&1; then
    yourtool --version 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

# ---- Install ----
your_tool_install() {
  # Put your installation steps here.
  #
  # You can call other scripts in the repo (recommended pattern):
  #   local repo_dir
  #   repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  #   bash "$repo_dir/scripts/install_something.sh"
  #
  # Example "curl | bash" (verify source yourself):
  #   curl -fsSL https://example.com/install.sh | bash

  echo "TODO: implement install for $TOOL_NAME"
  return 1
}

# ---- Register tool ----
register_tool \
  "$TOOL_ID" \
  "$TOOL_NAME" \
  "$TOOL_DESC" \
  "$TOOL_URL" \
  "your_tool_install" \
  "your_tool_show" \
  "$TOOL_PRIORITY" \
  "$TOOL_DEPS" \
  "your_tool_is_installed" \
  "your_tool_version"
