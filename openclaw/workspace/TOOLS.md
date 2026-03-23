# OpenClaw Smart Tools & Environment

**OS**: Arch Linux (rolling release)
**Shell**: fish (highly customized)
**User home**: `/home/johnpaul`
**Purpose**: This file tells OpenClaw (and any AI agent using it) exactly which modern, high-performance tools are available and how they are configured. Use these tools preferentially in all command suggestions.

## Full Fish Configuration (`~/.config/fish/config.fish`)

```fish
set -gx PATH $PATH "$HOME/.local/share/flatpak/exports/bin" "$HOME/.local/bin"

# pnpm
set -gx PNPM_HOME "/home/johnpaul/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# opencode
fish_add_path /home/johnpaul/.opencode/bin

# openclaw (global npm/pnpm binaries)
set -gx PATH $PATH "$(npm prefix -g)/bin"

# OpenClaw Completion
source "/home/johnpaul/.openclaw/completions/openclaw.fish"
```

## Tool Inventory (Preferred Tools)

| Category              | Tool          | Purpose                                      | Install / Location                     | Preferred Command Style                  |
|-----------------------|---------------|----------------------------------------------|----------------------------------------|------------------------------------------|
| **Shell**             | fish          | Modern, user-friendly shell                  | `sudo pacman -S fish`                  | Use fish syntax (`set -gx`, no `$`)     |
| **App Packaging**     | flatpak       | Sandboxed desktop/CLI apps                   | `sudo pacman -S flatpak`               | `flatpak install flathub ...`            |
| **JS/TS Runtime**     | bun           | All-in-one runtime, bundler, test runner     | `~/.bun/bin`                           | `bun run dev`, `bun add`, `bun test`    |
| **JS Package Manager**| pnpm          | Fast, disk-efficient Node.js manager         | `~/.local/share/pnpm`                  | `pnpm install`, `pnpm dlx`, `pnpm exec`  |
| **Search**            | ripgrep (rg)  | Blazing-fast grep with `.gitignore` support  | `sudo pacman -S ripgrep`               | `rg "pattern"`, `rg -t ts`, `rg --json`  |
| **Python Manager**    | uv            | Ultra-fast Python packaging & projects       | `~/.local/bin/uv` or `uv` in PATH      | `uv venv`, `uv pip install`, `uv run`    |
| **OpenClaw / Utils**  | openclaw      | Main CLI (global npm bin)                    | `$(npm prefix -g)/bin/openclaw`        | `openclaw ...`                           |
| **OpenCode**          | opencode      | Additional dev utilities                     | `~/.opencode/bin`                      | Use when relevant                        |

## How OpenClaw Should Use These Tools

### Always Prefer
- `rg` over `grep`, `ag`, `find`, `fd` (unless user explicitly asks otherwise)
- `pnpm` or `bun` over `npm` / `yarn`
- `uv` for any Python work (`uv run python ...`, `uvx ruff`, `uv tool install ...`)
- `bun` for any JS/TS runtime needs (scripts, tests, dev servers)
- Fish syntax in every code block or command suggestion
- Full paths only when necessary; rely on the PATH setup above

### Common Patterns OpenClaw Should Suggest
```fish
# Search
rg "TODO" --type ts
rg -i "error" src/

# JS/TS
pnpm install
bun --bun run dev
bun add -d eslint

# Python
uv venv
uv run python script.py
uv pip install -r requirements.txt --upgrade
uvx ruff check .

# Flatpak
flatpak run io.github.ungoogled_software.ungoogled_chromium

# OpenClaw itself
openclaw --help
```

## Notes for OpenClaw Agent
- User is on **Arch Linux + fish** → never suggest bash/zsh syntax.
- User loves **modern, fast tools** → always reach for `rg`, `uv`, `bun`, `pnpm` first.
- Global npm bin path is active → `openclaw` command is always available.
- Completions are loaded → suggest subcommands freely.
- Keep suggestions concise, use fish abbreviations where helpful (`abbr -a ...`).

**Last updated**: 2026-02-23  
**Maintained by**: OpenClaw (auto-generated from user environment)

---

