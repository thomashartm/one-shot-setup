# OneShotSetup

A reproducible macOS development machine bootstrapper you can keep in a Git repo and re-run after reinstalling macOS.

---

## Why This Exists

Setting up a new development machine shouldn't feel like archaeology. Every time you bootstrap a fresh MacBook, you face the same questions: *What did I install last time? Which tools did I actually use? How was everything configured?*

**OneShotSetup solves this with a simple philosophy:**

- **Your setup is code** - Keep it in Git, version it, share it across machines
- **Consistency matters** - Same tools, same configs, every time
- **Memory fades** - Let the script remember what you installed 6 months ago
- **Shell scripts are simple** - No complex frameworks, just Bash. Easy to read, easy to modify, runs anywhere
- **Bootstrapping should be boring** - Clone, run, get back to work

Whether you're setting up a new laptop, recovering from a clean install, or maintaining multiple development machines, OneShotSetup gives you a single command to restore your complete development environment.

---

## Key Features

- **Tool registry** - Numbered  list of available tools with descriptions
- **Dependency resolution** - Automatically installs dependencies first (e.g., Homebrew before tools that need it)
- **Reinstallation support** - Re-run installers to restore shell configs after accidental deletions or updates
- **State tracking** - Local state folder (`~/.one-shot-setup/`) with install history and version tracking
- **Safe verification** - `show` command opens official docs before installing
- **Status commands** - Check what's installed, view history, see versions

---

## Repository Layout

```
.
├── setup.sh              # Main CLI orchestrator
├── CLAUDE.md             # Project architecture guide
└── tools/                # One file per tool
    ├── homebrew.sh       # Package manager (priority 0)
    ├── oh-my-zsh.sh      # Shell framework
    ├── claude-code.sh    # Claude CLI
    ├── nvm-nodejs.sh     # Node.js via nvm
    ├── uv.sh             # Python package manager
    ├── gcloud-cli.sh     # Google Cloud CLI
    ├── go.sh             # Go programming language
    ├── docker-cli.sh     # Docker client
    ├── colima.sh         # Container runtime
    ├── ngnix.sh          # nginx HTTP server
    └── terraform-stack.sh # Terraform + Terragrunt
```

Each tool file is self-contained and declares its own dependencies.

---

## Requirements

- macOS (Darwin)
- Bash (macOS default Bash 3.2 is supported)

---

## Quick start

```bash
git clone <your-repo-url>
cd <your-repo-folder>

chmod +x setup.sh
./setup.sh list
````

---

## Commands

### List available tools

```bash
./setup.sh list
```

Shows a numbered list with:

* ID
* Name
* Priority
* Dependencies
* Description

### Show install pages

Open the tool’s official page in your browser:

```bash
./setup.sh show homebrew
./setup.sh show 1
./setup.sh show all
```

### Install tools

Install by id, number, or `all`:

```bash
./setup.sh install homebrew
./setup.sh install 1 3
./setup.sh install all
```

**Reinstallation:** Run the same command to reinstall/update a tool. Useful for:
- Restoring shell configs (.zshrc, .zshenv) after accidental deletions
- Updating tool configurations
- Fixing incomplete installations

Non-interactive mode:

```bash
./setup.sh install homebrew claude -y
```

Skip dependency expansion (advanced):

```bash
./setup.sh install claude --no-deps
```

### Check installation status and versions

```bash
./setup.sh status
```

Outputs install detection + current version for every registered tool.

### List installed tools

```bash
./setup.sh installed
```

Shows only tools currently detected as installed.

### View install history log

```bash
./setup.sh history
```
---

## State and Logs

State directory: `~/.one-shot-setup/`

```
installed.tsv   # tool id, name, first install date, current version
install.log     # append-only: timestamp, action, tool id, name, version
```

**Actions logged:** `installed`, `reinstalled`, `detected`, `skipped`, `failed`

The install log tracks every execution for auditing and troubleshooting.

---

## Tool Ordering: Priority + Dependencies

Each tool declares:
- **Priority** - Lower numbers run first (Homebrew is `0`, apps are `50+`)
- **Dependencies** - Tool IDs that must be installed before this tool

Example: Installing `claude` automatically installs `homebrew` first if needed.

```bash
./setup.sh install claude
# Installs: homebrew (priority 0) → claude (priority 30)
```

---

## Adding a New Tool

Create `tools/mytool.sh` and implement four functions:

```bash
mytool_show()          # Open tool's official URL
mytool_install()       # Install the tool (assumes dependencies available)
mytool_is_installed()  # Return 0 if installed, 1 if not
mytool_version()       # Print version string
```

Register the tool:

```bash
register_tool \
  "mytool" \           # Unique ID
  "MyTool" \           # Display name
  "Description" \      # Short description
  "https://url" \      # Official URL
  "mytool_install" \   # Install function
  "mytool_show" \      # Show function
  50 \                 # Priority (lower runs first)
  "homebrew" \         # Dependencies (space-separated IDs)
  "mytool_is_installed" \
  "mytool_version"
```

**Important:** See `.claude.md` for architecture principles:
- Never install or configure dependencies (only check/use them)
- Support reinstallation (check for complete config, remove incomplete blocks)
- Keep installations conservative (no extras)

---

## Safety

Some tools use `curl | bash` installers. Best practice:

1. `./setup.sh show <tool>` - Opens official documentation
2. Review the installer yourself
3. `./setup.sh install <tool>` - Run when ready

Always verify sources before installing.

---

## Roadmap

* Interactive multi-select UI
* `doctor` command - Diagnose PATH and environment issues
* `status --sync` - Refresh versions after external upgrades
* Brewfile integration - Full package reproducibility

---

## License

MIT
