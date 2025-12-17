#!/usr/bin/env bash
set -euo pipefail

die() { echo "Error: $*" >&2; exit 1; }

# Root of repo (scripts/..)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${REPO_DIR}/tools/_template.sh"
TOOLS_DIR="${REPO_DIR}/tools"

[[ -f "$TEMPLATE" ]] || die "Missing template: $TEMPLATE"
[[ -d "$TOOLS_DIR" ]] || die "Missing tools dir: $TOOLS_DIR"

read_trim() {
  # read_trim "Prompt: " -> echoes trimmed value
  local prompt="$1"
  local val
  read -r -p "$prompt" val || true
  # trim leading/trailing whitespace
  val="${val#"${val%%[![:space:]]*}"}"
  val="${val%"${val##*[![:space:]]}"}"
  echo "$val"
}

to_func_name() {
  # Convert tool id into a safe function prefix (hyphens -> underscores)
  echo "$1" | tr '-' '_' | tr ' ' '_' | tr -cd 'a-zA-Z0-9_'
}

escape_sed_repl() {
  # Escape &, \, and | for sed replacement
  echo "$1" | sed -e 's/[&\|\\]/\\&/g'
}

main() {
  echo "OneShotSetup - new tool generator"
  echo

  local tool_id tool_name tool_desc tool_url tool_priority tool_deps
  tool_id="$(read_trim "Tool id (e.g. node, oh-my-zsh): ")"
  [[ -n "$tool_id" ]] || die "Tool id is required."

  # Basic validation (keep it simple)
  if ! [[ "$tool_id" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    die "Tool id must match: ^[a-z0-9][a-z0-9-]*$ (lowercase, digits, hyphens)."
  fi

  tool_name="$(read_trim "Tool name (e.g. Node.js): ")"
  [[ -n "$tool_name" ]] || die "Tool name is required."

  tool_desc="$(read_trim "Description: ")"
  [[ -n "$tool_desc" ]] || die "Description is required."

  tool_url="$(read_trim "Install/info URL: ")"
  [[ -n "$tool_url" ]] || die "URL is required."

  tool_priority="$(read_trim "Priority (number, lower installs earlier) [50]: ")"
  tool_priority="${tool_priority:-50}"
  [[ "$tool_priority" =~ ^[0-9]+$ ]] || die "Priority must be a number."

  tool_deps="$(read_trim "Dependencies (space-separated tool ids) [homebrew]: ")"
  tool_deps="${tool_deps:-homebrew}"

  local out="${TOOLS_DIR}/${tool_id}.sh"
  [[ -f "$out" ]] && die "Tool file already exists: $out"

  local func_prefix
  func_prefix="$(to_func_name "$tool_id")"

  cp "$TEMPLATE" "$out"

  # macOS sed needs -i '' for in-place edits
  local sid sname sdesc surl sprio sdeps sprefix
  sid="$(escape_sed_repl "$tool_id")"
  sname="$(escape_sed_repl "$tool_name")"
  sdesc="$(escape_sed_repl "$tool_desc")"
  surl="$(escape_sed_repl "$tool_url")"
  sprio="$(escape_sed_repl "$tool_priority")"
  sdeps="$(escape_sed_repl "$tool_deps")"
  sprefix="$(escape_sed_repl "$func_prefix")"

  sed -i '' \
    -e "s|TOOL_ID=\"your-tool-id\"|TOOL_ID=\"${sid}\"|g" \
    -e "s|TOOL_NAME=\"Your Tool Name\"|TOOL_NAME=\"${sname}\"|g" \
    -e "s|TOOL_DESC=\"What this tool installs/configures\"|TOOL_DESC=\"${sdesc}\"|g" \
    -e "s|TOOL_URL=\"https://example.com/install\"|TOOL_URL=\"${surl}\"|g" \
    -e "s|TOOL_PRIORITY=50|TOOL_PRIORITY=${sprio}|g" \
    -e "s|TOOL_DEPS=\"homebrew\"|TOOL_DEPS=\"${sdeps}\"|g" \
    "$out"

  # Replace function names in the template:
  # your_tool_show / your_tool_install / your_tool_is_installed / your_tool_version
  sed -i '' \
    -e "s|your_tool_show|${sprefix}_show|g" \
    -e "s|your_tool_install|${sprefix}_install|g" \
    -e "s|your_tool_is_installed|${sprefix}_is_installed|g" \
    -e "s|your_tool_version|${sprefix}_version|g" \
    "$out"

  echo
  echo "Created: $out"
  echo
  echo "Next steps:"
  echo "  1) Edit the install logic in: tools/${tool_id}.sh"
  echo "  2) Test:"
  echo "
