# OneShotSetup

A reproducible macOS development machine bootstrapper you can keep in a Git repo and re-run after reinstalling macOS.

OneShotSetup provides:

- A **tool registry** (numbered list with name + description)
- `install` command to run official installers (including `curl | bash` flows)
- `show` command to open install pages for manual verification
- **Dependency-aware installs** (e.g. install Homebrew before tools that rely on it)
- A local **state folder** in your home directory:
  - install history log
  - installed tool registry (install date + version)
- Commands to check **status**, list **installed** tools, and view **history**

---

## Repository layout

```

.
├── osh-setup.sh
└── tools
├── homebrew.sh
├── oh-my-zsh.sh
└── claude.sh

````

- `osh-setup.sh` = main CLI
- `tools/*.sh` = tool “feature scripts” (each tool registers itself)
- `scripts/new-tool.sh` = interactive generator that creates `tools/<id>.sh`

---

## Requirements

- macOS (Darwin)
- Bash (macOS default Bash 3.2 is supported)

---

## Quick start

```bash
git clone <your-repo-url>
cd <your-repo-folder>

chmod +x osh-setup.sh
./osh-setup.sh list
````

---

## Commands

### List available tools

```bash
./osh-setup.sh list
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
./osh-setup.sh show homebrew
./osh-setup.sh show 1
./osh-setup.sh show all
```

### Install tools

Install by id, number, or `all`:

```bash
./osh-setup.sh install homebrew
./osh-setup.sh install 1 3
./osh-setup.sh install all
```

Non-interactive mode:

```bash
./osh-setup.sh install homebrew claude -y
```

Skip dependency expansion (advanced):

```bash
./osh-setup.sh install claude --no-deps
```

### Check installation status and versions

```bash
./osh-setup.sh status
```

Outputs install detection + current version for every registered tool.

### List installed tools

```bash
./osh-setup.sh installed
```

Shows only tools currently detected as installed.

### View install history log

```bash
./osh-setup.sh history
```
---
## Adding a new tool
### Option A: use the generator (recommended)
```bash
chmod +x scripts/new-tool.sh
./scripts/new-tool.sh
```

This will generate a new tool file at:
```bash
tools/<tool-id>.sh
```

Then edit the new file and implement the *_install() function.

### Option B: copy the template manually
```bash
cp tools/_template.sh tools/mytool.sh
```

Then replace placeholders and implement:
```bash
<tool>_show → opens URL

<tool>_install → performs install

<tool>_is_installed → exits 0 if installed, non-zero if not

<tool>_version → prints a version string
```

---

## State and logs

OneShotSetup writes state to:

```
~/.one-shot-setup/
  installed.tsv   # tool id, name, first install date, last known version
  install.log     # append-only log: timestamp, action, tool id, name, version
```

Notes:

* `installed.tsv` is updated after successful installs (and also when tools are detected as already installed).
* `install.log` is append-only for auditing and troubleshooting.

---

## Tool ordering: priority + dependencies

Each tool declares:

* **priority**: lower = more essential, installs earlier
* **deps**: tool ids that must be installed first

Example:

* Homebrew has priority `0`
* Other tools can depend on `homebrew`

So:

```bash
./osh-setup.sh install claude
```

will install `homebrew` first (if not installed), then `claude`.

---

## Adding a new tool

Create a new file under `tools/`, e.g. `tools/node.sh`, and implement:

* `<tool>_show` → opens URL
* `<tool>_install` → performs install
* `<tool>_is_installed` → exits 0 if installed, non-zero if not
* `<tool>_version` → prints a version string

Then register it:

```bash
register_tool \
  "node" \
  "Nodejs" \
  "Install Nodejs runtime" \
  "https://nodejs.org/" \
  "node_install" \
  "node_show" \
  40 \
  "homebrew" \
  "node_is_installed" \
  "node_version"
```

---

## Safety notes

This project may run official installers that use `curl | bash` or `curl | sh`.

Best practice:

1. Run `./osh-setup.sh show <tool>` to open the tool’s official page.
2. Verify the installer source and contents yourself.
3. Then run `./osh-setup.sh install <tool>`.

---

## Roadmap ideas

* Interactive multi-select installer UI
* `doctor` command (fix PATH issues, verify common requirements)
* `status --sync` (refresh recorded versions after upgrades)
* Brewfile support (`brew bundle`) for full package reproducibility

---

## License

MIT LICENSE
