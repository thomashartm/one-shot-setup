# One-Shot Setup - Project Guide for Claude

## Project Overview

One-Shot Setup (osh-setup.sh) is a macOS development tool bootstrapper that installs and configures development tools with proper dependency management and reinstallation support.

**Key Files:**
- `osh-setup.sh` - Main orchestration script with dependency resolution
- `tools/*.sh` - Individual tool installers (one file per tool)
- `scripts/*.sh` - Helper scripts for common tasks e.g.Cre to scaffold new tools

## Core Architecture Principles

### 1. **Dependency Isolation - CRITICAL**

Each tool file is responsible for **checking** its dependencies but **MUST NEVER install them**.

**✅ CORRECT:**
```bash
terraform_stack_install() {
  # Depends on homebrew (declared in register_tool)
  # Just use brew - dependency system ensures it's installed
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform
}
```

**❌ WRONG:**
```bash
nodejs_install() {
  # DO NOT DO THIS - never configure dependencies
  _ensure_homebrew_shellenv  # ❌ BAD - homebrew should manage its own config

  brew install nvm
}
```

**Why:** The dependency system in `osh-setup.sh` ensures dependencies are installed first (via priority and `deps` fields). Tools must trust this and only use their dependencies, never configure them.

### 2. **Re-execution Support**

All install functions must support re-running after initial installation. This enables:
- Config recovery when users accidentally delete shell config lines
- Updates and reinstalls
- Fixing incomplete installations

**Implementation Pattern:**

For config functions that modify shell files (.zshrc, .zshenv, .zprofile):

```bash
_tool_ensure_config() {
  local config_file="${HOME}/.zshrc"
  touch "$config_file"

  # ✅ Check if COMPLETE config exists (all required lines)
  if grep -Fq "# OneShotSetup: MyTool" "$config_file" && \
     grep -Fq "export MY_TOOL_VAR=" "$config_file" && \
     grep -Fq "source /path/to/tool" "$config_file"; then
    return 0  # Complete config present
  fi

  # ✅ Remove incomplete/old config block before re-adding
  if grep -Fq "# OneShotSetup: MyTool" "$config_file"; then
    echo "Removing incomplete MyTool config from $config_file"
    local tmp_file
    tmp_file="$(mktemp)"
    awk '
      /# OneShotSetup: MyTool/ { skip=1; next }
      skip && /^[[:space:]]*$/ { skip=0; next }
      skip && /^[[:space:]]*(export|source|#)/ { next }
      { if (!skip) print }
    ' "$config_file" > "$tmp_file"
    mv "$tmp_file" "$config_file"
  fi

  # ✅ Add fresh complete config
  {
    echo
    echo "# OneShotSetup: MyTool"
    echo "export MY_TOOL_VAR=value"
    echo "source /path/to/tool"
  } >> "$config_file"
}
```

**Anti-patterns:**
```bash
# ❌ BAD - only checks for marker, not complete config
if grep -Fq "# OneShotSetup: MyTool" "$config_file"; then
  return 0  # Could be incomplete!
fi

# ❌ BAD - early return prevents reinstall
my_tool_install() {
  if my_tool_is_installed; then
    return 0  # ❌ Prevents config recovery
  fi
  # ... install
}
```

### 3. **Conservative Installations**

Each tool should install **only what it needs**, nothing more.

**✅ DO:**
- Install the specific tool
- Configure that tool's shell integration
- Add that tool's binaries to PATH

**❌ DON'T:**
- Install "helpful" extra packages
- Configure unrelated tools
- Add global settings outside the tool's scope
- Install plugins or extensions without explicit need

**Example:**
```bash
docker_cli_install() {
  # ✅ Install only docker client
  brew install docker

  echo "Tip: Start runtime with: colima start"
  # ✅ Inform user, don't auto-install colima
}
```

### 4. **One Tool Per File**

Each `tools/*.sh` file manages exactly one logical tool (or tightly coupled stack).

**✅ GOOD:**
- `homebrew.sh` - Just Homebrew
- `nvm-nodejs.sh` - nvm + Node.js (tightly coupled)
- `terraform-stack.sh` - Terraform + Terragrunt (commonly used together)

**❌ BAD:**
- `dev-tools.sh` - Multiple unrelated tools
- Tool file that installs both Python and Go

### 5. **Dependency Declaration**

Tools declare dependencies via the `register_tool` function:

```bash
register_tool \
  "tool-id" \
  "Tool Name" \
  "Description" \
  "https://url" \
  "tool_install" \
  "tool_show" \
  50 \                    # Priority (lower runs first)
  "homebrew other-tool" \ # Dependencies (space-separated IDs)
  "tool_is_installed" \
  "tool_version"
```

**Dependency Resolution:**
- Dependencies are installed before the tool (automatic)
- Tool can safely assume dependencies are available
- Tool must **never** install or configure dependencies

## Tool File Template

```bash
# Tool: MyTool - Brief description
# Depends on: homebrew (or other-tool)
# Optional: Links to official docs/install guides

mytool_show() {
  open_url "https://mytool.example.com"
}

mytool_is_installed() {
  command -v mytool >/dev/null 2>&1
}

mytool_version() {
  if command -v mytool >/dev/null 2>&1; then
    mytool --version 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

# Config helper function (if tool needs shell config)
_mytool_ensure_config() {
  local config_file="${HOME}/.zshrc"
  touch "$config_file"

  # Check for COMPLETE config
  if grep -Fq "# OneShotSetup: MyTool" "$config_file" && \
     grep -Fq "required_line" "$config_file"; then
    return 0
  fi

  # Remove incomplete config
  if grep -Fq "# OneShotSetup: MyTool" "$config_file"; then
    echo "Removing incomplete MyTool config from $config_file"
    local tmp_file
    tmp_file="$(mktemp)"
    awk '
      /# OneShotSetup: MyTool/ { skip=1; next }
      skip && /^[[:space:]]*$/ { skip=0; next }
      skip && /^[[:space:]]*(export|source)/ { next }
      { if (!skip) print }
    ' "$config_file" > "$tmp_file"
    mv "$tmp_file" "$config_file"
  fi

  # Add fresh config
  {
    echo
    echo "# OneShotSetup: MyTool"
    echo "# Config lines here"
  } >> "$config_file"
}

mytool_install() {
  # ✅ Use dependencies (don't install/configure them)
  brew install mytool

  # ✅ Configure this tool only
  _mytool_ensure_config

  echo "Done. Verify with: mytool --version"
}

register_tool \
  "mytool" \
  "MyTool" \
  "Install MyTool via Homebrew" \
  "https://mytool.example.com" \
  "mytool_install" \
  "mytool_show" \
  50 \
  "homebrew" \
  "mytool_is_installed" \
  "mytool_version"
```

## Main Script (`osh-setup.sh`)

### Re-execution Logic

The main script's `run_install` function (lines 308-381) handles reinstallation:

1. Always prompts user for install/reinstall (no auto-skip)
2. Different prompts for new vs existing installations
3. Logs actions: `installed`, `reinstalled`, `skipped`, `detected`, `failed`
4. Preserves first install timestamp across reinstalls

**Do not modify this logic** - it's designed to enable tool reinstallation.

### State Management

State files in `~/.one-shot-setup/`:
- `installed.tsv` - Currently installed tools (id, name, timestamp, version)
- `install.log` - Append-only log of all install actions

## Common Patterns

### Pattern 1: Simple Binary Installation
```bash
tool_install() {
  brew install tool-name
}
```

### Pattern 2: Installation + Shell Config
```bash
tool_install() {
  brew install tool-name
  _tool_ensure_config
}
```

### Pattern 3: Multiple Related Tools
```bash
stack_install() {
  brew install tool1
  brew install tool2
  _stack_ensure_config  # Shared config if needed
}
```

### Pattern 4: Custom Installer
```bash
tool_install() {
  curl -fsSL https://example.com/install.sh | bash
  _tool_ensure_config
}
```

## What to Check During Code Review

### ✅ Good Signs
- [ ] Each tool file manages one tool/stack
- [ ] Config functions check for **complete** config (not just markers)
- [ ] Incomplete configs are removed before re-adding
- [ ] No early returns that prevent reinstallation
- [ ] Dependencies declared, never installed by the tool
- [ ] Conservative installations (no extras)
- [ ] Clear marker comments: `# OneShotSetup: ToolName`

### ❌ Red Flags
- [ ] Tool configures its dependencies
- [ ] Config function only checks for marker comment
- [ ] Early return: `if tool_is_installed; then return 0; fi`
- [ ] Installing "helpful" extra packages
- [ ] Modifying global config outside tool scope
- [ ] Multiple unrelated tools in one file

## Adding a New Tool

1. Create `tools/mytool.sh`
2. Implement required functions (see template above)
3. Declare dependencies accurately
4. Test initial install: `./osh-setup.sh install mytool`
5. Test reinstall (delete a config line): `./osh-setup.sh install mytool`
6. Verify complete config restored

## Testing Reinstallation

For any tool with shell config:

```bash
# Initial install
./osh-setup.sh install mytool

# Verify config added
grep "OneShotSetup: MyTool" ~/.zshrc

# Simulate user error - delete one line from the block
vim ~/.zshrc  # Delete one line from MyTool config

# Reinstall
./osh-setup.sh install mytool

# Verify complete config restored
grep -A 5 "OneShotSetup: MyTool" ~/.zshrc
```

## Priority Guidelines

Tools run in priority order (lower number = runs first):

- `0-10`: Core dependencies (homebrew)
- `20-30`: Shell frameworks (oh-my-zsh)
- `40-50`: Languages & runtimes (nvm, uv, terraform)
- `50+`: Applications (claude, docker)

Choose priority based on how many other tools depend on it.

## Remember

**The golden rule:** A tool should assume its dependencies are available and working. It should never try to fix, install, or configure them. If there's a dependency problem, it should fail with a clear error message.
