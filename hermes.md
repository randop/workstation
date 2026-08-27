# Hermes

## Set up **Hermes Agent**

**1. Install**
```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
source ~/.bashrc
```

**2. Pick a model provider**
```bash
hermes model
```
Or for the fastest path (free OAuth, no API keys):
```bash
hermes setup --portal
```

**3. Enable the browser toolset**
```bash
hermes config set toolsets '["hermes-cli", "browser"]'
```
No manual Chrome install is needed — `agent-browser` (the CDP driver) resolves automatically via `npx` on first use. To skip that one-time fetch, install it globally:
```bash
npm install -g agent-browser
```

**4. Headless mode is the default**
If you set no cloud credentials and don't run `/browser connect`, Hermes drives a local Chromium install headlessly through `agent-browser`. Nothing further is required — just start chatting and ask it to browse:
```bash
hermes
```
```
Navigate to https://github.com/trending and summarize the top repos
```

**5. Config knobs (in `~/.hermes/config.yaml`)**
```yaml
browser:
  headed: false        # default; true shows a visible window instead
  engine: auto          # or "chrome" / "lightpanda"
  snapshot_threshold: 15000
  record_sessions: false
```
Or via env var: `AGENT_BROWSER_ENGINE=auto`

**6. If you'd rather attach to your own already-running Chrome** (still scriptable/headless-capable) instead of a fresh sandboxed instance:
```bash
google-chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=$HOME/.hermes/chrome-debug \
  --headless=new \
  --no-first-run --no-default-browser-check &
```
Then in the Hermes CLI:
```
/browser connect
```
Note: this must be run from a real terminal (`hermes` / `hermes chat`) — it won't work from a gateway chat like Telegram/Discord. Also, Chrome 136+ refuses to open the debug port unless you pass a non-default `--user-data-dir`.

**Available tools once connected:** `browser_navigate`, `browser_snapshot`, `browser_click`, `browser_type`, `browser_scroll`, `browser_press`, `browser_get_images`, `browser_vision`, `browser_console`, and `browser_cdp` (raw CDP passthrough) for anything not covered above.

For root/container environments, Hermes auto-injects `--no-sandbox --disable-dev-shm-usage` when needed, so you usually don't have to set those flags yourself.
