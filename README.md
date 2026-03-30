# claude-project-status

Shell prompt integration for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) projects. Like Git shows your branch in the prompt, this shows when you're inside a Claude-enabled project.

```
user@host ~/lab/metale (main) [claude:metale md,local] $
                               └─────────────────────┘
                               appears when inside a Claude project
```

In **Warp Terminal**, the segment appears on the right side of the prompt automatically.

## Install

### One-liner

```sh
git clone https://github.com/ciocan/claude-project-status.git ~/.claude-project-status
~/.claude-project-status/install.sh
exec $SHELL
```

### Manual

**Zsh** — add to `~/.zshrc` (after oh-my-zsh source line if applicable):

```zsh
source ~/.claude-project-status/integrations/zsh.zsh
```

**Bash** — add to `~/.bashrc`:

```bash
source ~/.claude-project-status/integrations/bash.bash
```

**Fish** — add to `~/.config/fish/config.fish`:

```fish
source ~/.claude-project-status/integrations/fish.fish
```

Then add `(claude_project_segment)` to your `fish_prompt` function.

**Starship** — copy the module from `integrations/starship.toml` into `~/.config/starship.toml`.

### CLI tool (optional)

Make `claude-project-info` available globally:

```sh
./install.sh --link    # symlinks to ~/.local/bin/
```

### Uninstall

```sh
./uninstall.sh
exec $SHELL
```

## What It Detects

A directory is a **Claude project** if it or any ancestor contains:

| Marker | Flag | Meaning |
|--------|------|---------|
| `.claude/` | — | Project has Claude configuration |
| `CLAUDE.md` | `md` | Project instructions file |
| `.claude/settings.json` | `cfg` | Project settings |
| `.claude/settings.local.json` | `local` | Local permission overrides |

Detection walks up from your current directory to `/`, stopping at the first match — just like Git finds `.git/`. Your home directory is excluded (`~/.claude/` is global config, not a project).

## Terminal Support

The integration auto-detects your terminal and adapts:

| Terminal | Behavior |
|----------|----------|
| **Warp** (default) | Segment in RPROMPT (right side) — Warp ignores PS1 by default |
| **Warp** + `WARP_HONOR_PS1=1` | Segment in PROMPT (left side) |
| **iTerm2, Terminal.app, Alacritty, etc.** | Segment in PROMPT (left side) |

No configuration needed — it just works.

## CLI Tool

`claude-project-info` provides project metadata for scripting and manual queries.

```sh
$ claude-project-info
Claude Project: metale
Root:           /Users/c/lab/metale
Flags:          md,local

Markers:
  ✓ .claude/ directory
  ✓ CLAUDE.md
  ✗ .claude/settings.json
  ✓ .claude/settings.local.json

$ claude-project-info --json
{"is_project": true, "root": "/Users/c/lab/metale", "name": "metale", ...}

$ claude-project-info --name
metale

$ claude-project-info --quiet && echo "in a project"
in a project
```

| Flag | Description |
|------|-------------|
| `-j, --json` | JSON output |
| `-q, --quiet` | Exit code only (0 = project, 1 = not) |
| `-r, --root` | Print project root path |
| `-n, --name` | Print project name |
| `-f, --flags` | Print flags |
| `-s, --sessions` | Include session count from `~/.claude/projects/` |
| `--no-color` | Disable colors |
| `--format STR` | Custom format (`%n` = name, `%f` = flags, `%r` = root) |

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `CLAUDE_PROMPT_DISABLE` | unset | Set to `1` to hide the segment |
| `CLAUDE_PROJECT_ROOT` | unset | Override detected root (skip walk-up) |
| `CLAUDE_PROMPT_COLOR` | auto | `0` = plain text, `1` = force color |
| `CLAUDE_PROMPT_FORMAT` | `[claude:%n %f]` | Custom format string |

### Custom format examples

```sh
export CLAUDE_PROMPT_FORMAT="⚡%n"           # → ⚡metale
export CLAUDE_PROMPT_FORMAT="[%n|%f]"        # → [metale|md,local]
export CLAUDE_PROMPT_FORMAT="claude:%n@%r"   # → claude:metale@/Users/c/lab/metale
```

## Performance

Runs on every prompt render, so speed matters:

| Scenario | Time |
|----------|------|
| Cache hit (same directory) | **~0ms** — pure variable read |
| Cache miss (directory changed) | **~2ms** — stat-only walk-up |
| Worst case | **<10ms** |

Implemented in POSIX shell. No Python, Node, or external dependencies.

## How It Works

1. On every prompt render, a `precmd` hook (zsh) or `PROMPT_COMMAND` (bash) fires
2. If `$PWD` hasn't changed, returns the cached result immediately (zero I/O)
3. Otherwise, walks up from `$PWD` checking each directory for `.claude/` or `CLAUDE.md`
4. Stops at the first match, gathers flags, formats the output, caches it
5. The formatted segment is injected into `PROMPT` (or `RPROMPT` in Warp)

## Project Structure

```
bin/claude-project-info      # Standalone CLI tool
lib/
  detect.sh                  # Core walk-up detection + PWD caching
  format.sh                  # Output formatting (zsh/bash/plain colors)
  encode.sh                  # Path encoding for ~/.claude/projects/ lookups
integrations/
  zsh.zsh                    # Zsh precmd hook + auto PROMPT patching
  bash.bash                  # Bash PROMPT_COMMAND integration
  fish.fish                  # Fish shell integration
  starship.toml              # Starship custom module config
install.sh                   # Idempotent installer
uninstall.sh                 # Clean removal
test/                        # Test suite (43 unit tests)
```

## Tests

```sh
sh test/run_tests.sh
```

## License

MIT
