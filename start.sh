#!/usr/bin/env bash
set -euo pipefail

# ---------------- State ----------------
STATE_DIR="${HOME}/.one-shot-setup"
STATE_FILE="${STATE_DIR}/installed.tsv"   # id \t name \t installed_at \t version
LOG_FILE="${STATE_DIR}/install.log"       # iso \t action \t id \t name \t version

ensure_state_dir() {
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR" || true
  [[ -f "$STATE_FILE" ]] || : > "$STATE_FILE"
  [[ -f "$LOG_FILE" ]] || : > "$LOG_FILE"
}

iso_now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

log_append() {
  # log_append <action> <id> <name> <version>
  ensure_state_dir
  local ts action id name version
  ts="$(iso_now_utc)"
  action="$1"; id="$2"; name="$3"; version="$4"
  printf "%s\t%s\t%s\t%s\t%s\n" "$ts" "$action" "$id" "$name" "$version" >> "$LOG_FILE"
}

state_get_installed_at() {
  # echo installed_at if exists else empty
  ensure_state_dir
  local id="$1"
  local sid sname sat sver
  while IFS=$'\t' read -r sid sname sat sver; do
    [[ -n "${sid:-}" ]] || continue
    if [[ "$sid" == "$id" ]]; then
      echo "${sat:-}"
      return 0
    fi
  done < "$STATE_FILE"
  echo ""
}

state_upsert() {
  # state_upsert <id> <name> <installed_at> <version>
  ensure_state_dir
  local id="$1" name="$2" installed_at="$3" version="$4"
  local tmp found
  tmp="$(mktemp "${STATE_DIR}/installed.XXXXXX")"
  found=0

  local sid sname sat sver
  while IFS=$'\t' read -r sid sname sat sver; do
    [[ -n "${sid:-}" ]] || continue
    if [[ "$sid" == "$id" ]]; then
      printf "%s\t%s\t%s\t%s\n" "$id" "$name" "$installed_at" "$version" >> "$tmp"
      found=1
    else
      printf "%s\t%s\t%s\t%s\n" "$sid" "$sname" "$sat" "$sver" >> "$tmp"
    fi
  done < "$STATE_FILE"

  if [[ "$found" -eq 0 ]]; then
    printf "%s\t%s\t%s\t%s\n" "$id" "$name" "$installed_at" "$version" >> "$tmp"
  fi

  mv "$tmp" "$STATE_FILE"
}

# ---------------- Registry (Bash 3.2 compatible) ----------------
TOOLS_COUNT=0
TOOL_ID=()
TOOL_NAME=()
TOOL_DESC=()
TOOL_URL=()
TOOL_INSTALL_FN=()
TOOL_SHOW_FN=()
TOOL_PRIO=()          # integer, lower runs earlier
TOOL_DEPS=()          # space-separated tool ids
TOOL_ISINSTALLED_FN=()
TOOL_VERSION_FN=()    # echoes version string

register_tool() {
  # register_tool "<id>" "<name>" "<desc>" "<url>" "<install_fn>" "<show_fn>" "<priority>" "<deps>" "<is_installed_fn>" "<version_fn>"
  local id="$1" name="$2" desc="$3" url="$4" install_fn="$5" show_fn="$6"
  local prio="${7:-50}"
  local deps="${8:-}"
  local is_installed_fn="${9:-}"
  local version_fn="${10:-}"

  TOOL_ID[$TOOLS_COUNT]="$id"
  TOOL_NAME[$TOOLS_COUNT]="$name"
  TOOL_DESC[$TOOLS_COUNT]="$desc"
  TOOL_URL[$TOOLS_COUNT]="$url"
  TOOL_INSTALL_FN[$TOOLS_COUNT]="$install_fn"
  TOOL_SHOW_FN[$TOOLS_COUNT]="$show_fn"
  TOOL_PRIO[$TOOLS_COUNT]="$prio"
  TOOL_DEPS[$TOOLS_COUNT]="$deps"
  TOOL_ISINSTALLED_FN[$TOOLS_COUNT]="$is_installed_fn"
  TOOL_VERSION_FN[$TOOLS_COUNT]="$version_fn"
  TOOLS_COUNT=$((TOOLS_COUNT + 1))
}

is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
die() { echo "Error: $*" >&2; exit 1; }
open_url() { command -v open >/dev/null 2>&1 && open "$1" || echo "$1"; }

confirm() {
  local prompt="${1:-Continue?}"
  read -r -p "$prompt [y/N] " ans || true
  [[ "${ans:-}" == "y" || "${ans:-}" == "Y" ]]
}

usage() {
  cat <<'EOF'
MacMason (start.sh) - macOS dev tool bootstrapper

State:
  ~/.one-shot-setup/installed.tsv   # installed registry
  ~/.one-shot-setup/install.log     # append-only install log

Usage:
  ./start.sh list
  ./start.sh show <selection...>
  ./start.sh install <selection...> [-y|--yes] [--no-deps]
  ./start.sh status
  ./start.sh installed
  ./start.sh history
  ./start.sh help

Selections:
  - tool number from `list` (e.g. 1)
  - tool id (e.g. homebrew)
  - all

Examples:
  ./start.sh list
  ./start.sh status
  ./start.sh installed
  ./start.sh install claude -y
EOF
}

load_tools() {
  local tools_dir
  tools_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools"
  [[ -d "$tools_dir" ]] || die "Missing tools directory: $tools_dir"

  # shellcheck disable=SC1090
  for f in "$tools_dir"/*.sh; do
    [[ -f "$f" ]] || continue
    source "$f"
  done
}

print_list() {
  printf "\n%-4s %-15s %-18s %-6s %-18s %s\n" "No." "ID" "Name" "Prio" "Deps" "Description"
  printf "%-4s %-15s %-18s %-6s %-18s %s\n" "----" "---------------" "------------------" "----" "------------------" "-----------"
  local i
  for ((i=0; i<TOOLS_COUNT; i++)); do
    printf "%-4s %-15s %-18s %-6s %-18s %s\n" \
      "$((i+1))" "${TOOL_ID[$i]}" "${TOOL_NAME[$i]}" "${TOOL_PRIO[$i]}" "${TOOL_DEPS[$i]:-}" "${TOOL_DESC[$i]}"
  done
  echo
}

find_index_by_id() {
  local id="$1" i
  for ((i=0; i<TOOLS_COUNT; i++)); do
    [[ "${TOOL_ID[$i]}" == "$id" ]] && { echo "$i"; return 0; }
  done
  return 1
}

resolve_selection_to_index() {
  local sel="$1"
  if [[ "$sel" =~ ^[0-9]+$ ]]; then
    local n="$sel"
    (( n >= 1 && n <= TOOLS_COUNT )) && { echo $((n-1)); return 0; }
    return 1
  fi
  find_index_by_id "$sel"
}

# ---- Safe sorting (handles empty args under set -u) ----
sort_indices_by_prio() {
  (( $# == 0 )) && { echo ""; return 0; }
  local arr=("$@")
  local i j tmp
  for ((i=0; i<${#arr[@]}; i++)); do
    for ((j=i+1; j<${#arr[@]}; j++)); do
      if (( TOOL_PRIO[${arr[$j]}] < TOOL_PRIO[${arr[$i]}] )); then
        tmp="${arr[$i]}"; arr[$i]="${arr[$j]}"; arr[$j]="$tmp"
      fi
    done
  done
  echo "${arr[*]}"
}

deps_indices_for() {
  local idx="$1"
  local deps_str="${TOOL_DEPS[$idx]:-}"
  [[ -n "$deps_str" ]] || { echo ""; return 0; }

  local deps=()
  local dep_id dep_idx
  for dep_id in $deps_str; do
    dep_idx="$(find_index_by_id "$dep_id" || true)"
    [[ -n "${dep_idx:-}" ]] || die "Tool '${TOOL_ID[$idx]}' depends on unknown tool id: '$dep_id'"
    deps+=("$dep_idx")
  done

  if (( ${#deps[@]} > 1 )); then
    # shellcheck disable=SC2206
    deps=( $(sort_indices_by_prio "${deps[@]}") )
  fi

  (( ${#deps[@]} == 0 )) && echo "" || echo "${deps[*]}"
}

# ---- Dependency expansion via DFS (deps first), cycle safe ----
VISITING=()
VISITED=()
ORDER=()

dfs_visit() {
  local idx="$1"
  [[ "${VISITED[$idx]:-0}" == "1" ]] && return 0
  [[ "${VISITING[$idx]:-0}" == "1" ]] && die "Dependency cycle detected at '${TOOL_ID[$idx]}'"

  VISITING[$idx]=1
  local dep_indices dep_idx
  dep_indices="$(deps_indices_for "$idx")"
  for dep_idx in $dep_indices; do
    dfs_visit "$dep_idx"
  done
  VISITING[$idx]=0
  VISITED[$idx]=1
  ORDER+=("$idx")
}

expand_and_order_indices() {
  local initial=("$@")
  ORDER=(); VISITING=(); VISITED=()

  if (( ${#initial[@]} > 1 )); then
    # shellcheck disable=SC2206
    initial=( $(sort_indices_by_prio "${initial[@]}") )
  fi

  local idx
  for idx in "${initial[@]}"; do
    dfs_visit "$idx"
  done

  echo "${ORDER[*]}"
}

collect_initial_indices() {
  local sels=("$@")
  local indices=()
  local i sel idx

  (( ${#sels[@]} > 0 )) || die "No selection provided. Use: ./start.sh list"

  if [[ "${sels[0]}" == "all" ]]; then
    for ((i=0; i<TOOLS_COUNT; i++)); do indices+=("$i"); done
    echo "${indices[*]}"
    return 0
  fi

  for sel in "${sels[@]}"; do
    idx="$(resolve_selection_to_index "$sel" || true)"
    [[ -n "${idx:-}" ]] || die "Unknown selection: '$sel' (use ./start.sh list)"
    indices+=("$idx")
  done

  echo "${indices[*]}"
}

tool_is_installed() {
  local idx="$1"
  local fn="${TOOL_ISINSTALLED_FN[$idx]:-}"
  [[ -n "$fn" ]] || return 1
  "$fn"
}

tool_version() {
  local idx="$1"
  local fn="${TOOL_VERSION_FN[$idx]:-}"
  if [[ -n "$fn" ]]; then
    "$fn"
  else
    echo "unknown"
  fi
}

run_show() {
  local indices=("$@")
  local idx fn
  for idx in "${indices[@]}"; do
    fn="${TOOL_SHOW_FN[$idx]}"
    [[ -n "$fn" ]] || die "Tool has no show function: ${TOOL_ID[$idx]}"
    "$fn"
  done
}

run_install() {
  local yes="${YES:-0}"
  local indices=("$@")
  local idx fn name id

  ensure_state_dir

  for idx in "${indices[@]}"; do
    id="${TOOL_ID[$idx]}"
    name="${TOOL_NAME[$idx]}"
    fn="${TOOL_INSTALL_FN[$idx]}"
    [[ -n "$fn" ]] || die "Tool has no install function: $id"

    local already version installed_at_now recorded_at
    already=0
    if tool_is_installed "$idx"; then
      already=1
    fi

    version="$(tool_version "$idx")"
    recorded_at="$(state_get_installed_at "$id")"
    installed_at_now="${recorded_at:-$(iso_now_utc)}"

    echo "----"
    echo "Tool: $name ($id)"
    echo "URL:  ${TOOL_URL[$idx]}"

    if [[ "$already" -eq 1 ]]; then
      echo "Status: already installed (version: $version)"
      # If it wasn't recorded yet, record it as "detected"
      if [[ -z "${recorded_at:-}" ]]; then
        state_upsert "$id" "$name" "$installed_at_now" "$version"
        log_append "detected" "$id" "$name" "$version"
      else
        log_append "already" "$id" "$name" "$version"
      fi
      continue
    fi

    if [[ "$yes" -eq 1 ]] || confirm "Run installer for '$name'?"; then
      set +e
      "$fn"
      local rc=$?
      set -e

      if [[ "$rc" -ne 0 ]]; then
        log_append "failed" "$id" "$name" "unknown"
        die "Installer failed for '$name' (exit code $rc)"
      fi

      # Re-check after install
      if tool_is_installed "$idx"; then
        version="$(tool_version "$idx")"
        # Keep first install date if it exists, otherwise set now
        recorded_at="$(state_get_installed_at "$id")"
        installed_at_now="${recorded_at:-$(iso_now_utc)}"
        state_upsert "$id" "$name" "$installed_at_now" "$version"
        log_append "installed" "$id" "$name" "$version"
        echo "Done: $name (version: $version)"
      else
        log_append "failed" "$id" "$name" "unknown"
        die "Install finished but '$name' still not detected as installed."
      fi
    else
      log_append "skipped" "$id" "$name" "$version"
      echo "Skipped: $name"
    fi
  done
}

cmd_status() {
  ensure_state_dir
  printf "\n%-15s %-18s %-10s %-24s %s\n" "ID" "Name" "Installed" "RecordedInstallDate" "CurrentVersion"
  printf "%-15s %-18s %-10s %-24s %s\n" "---------------" "------------------" "---------" "------------------------" "-------------"

  local i installed version recorded
  for ((i=0; i<TOOLS_COUNT; i++)); do
    if tool_is_installed "$i"; then
      installed="yes"
      version="$(tool_version "$i")"
    else
      installed="no"
      version="-"
    fi
    recorded="$(state_get_installed_at "${TOOL_ID[$i]}")"
    [[ -n "${recorded:-}" ]] || recorded="-"

    printf "%-15s %-18s %-10s %-24s %s\n" \
      "${TOOL_ID[$i]}" "${TOOL_NAME[$i]}" "$installed" "$recorded" "$version"
  done
  echo
}

cmd_installed() {
  ensure_state_dir
  printf "\n%-15s %-18s %-24s %s\n" "ID" "Name" "RecordedInstallDate" "CurrentVersion"
  printf "%-15s %-18s %-24s %s\n" "---------------" "------------------" "------------------------" "-------------"

  local i version recorded any
  any=0
  for ((i=0; i<TOOLS_COUNT; i++)); do
    if tool_is_installed "$i"; then
      any=1
      version="$(tool_version "$i")"
      recorded="$(state_get_installed_at "${TOOL_ID[$i]}")"
      [[ -n "${recorded:-}" ]] || recorded="-"
      printf "%-15s %-18s %-24s %s\n" \
        "${TOOL_ID[$i]}" "${TOOL_NAME[$i]}" "$recorded" "$version"
    fi
  done

  if [[ "$any" -eq 0 ]]; then
    echo "(none detected as installed)"
  fi
  echo
}

cmd_history() {
  ensure_state_dir
  if [[ ! -s "$LOG_FILE" ]]; then
    echo "(install log is empty)"
    return 0
  fi
  echo
  cat "$LOG_FILE"
  echo
}

main() {
  is_macos || die "This script is intended for macOS (Darwin)."
  load_tools

  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    list)
      print_list
      ;;
    show)
      local initial
      initial="$(collect_initial_indices "$@")"
      # shellcheck disable=SC2206
      run_show ${initial}
      ;;
    install)
      YES=0
      NO_DEPS=0
      local sels=()
      local arg
      for arg in "$@"; do
        case "$arg" in
          -y|--yes) YES=1 ;;
          --no-deps) NO_DEPS=1 ;;
          *) sels+=("$arg") ;;
        esac
      done

      local initial ordered
      initial="$(collect_initial_indices "${sels[@]}")"

      if [[ "$NO_DEPS" -eq 1 ]]; then
        ordered="$initial"
      else
        # shellcheck disable=SC2206
        ordered="$(expand_and_order_indices ${initial})"
      fi

      # shellcheck disable=SC2206
      run_install ${ordered}
      ;;
    status)
      cmd_status
      ;;
    installed)
      cmd_installed
      ;;
    history)
      cmd_history
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      die "Unknown command: $cmd (use ./start.sh help)"
      ;;
  esac
}

main "$@"
