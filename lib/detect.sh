#!/bin/sh
# claude-project-status: Core detection logic
# Walks up from $PWD to find Claude project markers (.claude/ or CLAUDE.md)
# Designed for prompt-render speed: caches results keyed on $PWD

# Cache variables (persist across prompt renders within a shell session)
_CLAUDE_PS_CACHED_PWD=""
_CLAUDE_PS_CACHED_OUTPUT=""
_CLAUDE_PS_ROOT=""
_CLAUDE_PS_NAME=""
_CLAUDE_PS_FLAGS=""

# Main detection function. Call this on every prompt render.
# Sets: _CLAUDE_PS_ROOT, _CLAUDE_PS_NAME, _CLAUDE_PS_FLAGS, _CLAUDE_PS_CACHED_OUTPUT
_claude_detect_project() {
    # Kill switch — clear cache key so re-enable triggers fresh detection
    if [ "${CLAUDE_PROMPT_DISABLE:-0}" = "1" ]; then
        _CLAUDE_PS_CACHED_PWD=""
        _CLAUDE_PS_CACHED_OUTPUT=""
        _CLAUDE_PS_ROOT=""
        _CLAUDE_PS_NAME=""
        _CLAUDE_PS_FLAGS=""
        return 0
    fi

    # Cache hit — same directory, skip all filesystem work
    if [ "$_CLAUDE_PS_CACHED_PWD" = "$PWD" ]; then
        return 0
    fi

    local root=""
    local has_claude_dir=0
    local has_claude_md=0
    local has_settings_json=0
    local has_settings_local=0

    # If user overrides root, use it directly
    if [ -n "${CLAUDE_PROJECT_ROOT:-}" ]; then
        if [ -d "$CLAUDE_PROJECT_ROOT" ]; then
            root="$CLAUDE_PROJECT_ROOT"
        fi
    else
        # Walk up from $PWD to filesystem root
        local dir="$PWD"
        while true; do
            # Check for .claude/ directory (strongest signal)
            if [ -d "$dir/.claude" ]; then
                root="$dir"
                break
            fi
            # Check for CLAUDE.md file
            if [ -f "$dir/CLAUDE.md" ]; then
                root="$dir"
                break
            fi
            # Reached filesystem root — stop
            if [ "$dir" = "/" ]; then
                break
            fi
            # Move up one level
            dir=$(dirname "$dir")
        done
    fi

    # Exclude $HOME — ~/.claude/ is global config, not a project
    if [ "$root" = "$HOME" ]; then
        root=""
    fi

    # No project found
    if [ -z "$root" ]; then
        _CLAUDE_PS_CACHED_PWD="$PWD"
        _CLAUDE_PS_CACHED_OUTPUT=""
        _CLAUDE_PS_ROOT=""
        _CLAUDE_PS_NAME=""
        _CLAUDE_PS_FLAGS=""
        return 0
    fi

    # Stat marker files at the detected root
    [ -d "$root/.claude" ]                     && has_claude_dir=1
    [ -f "$root/CLAUDE.md" ]                   && has_claude_md=1
    [ -f "$root/.claude/settings.json" ]       && has_settings_json=1
    [ -f "$root/.claude/settings.local.json" ] && has_settings_local=1

    # Build flags string
    local flags=""
    if [ "$has_claude_md" = "1" ]; then
        flags="md"
    fi
    if [ "$has_settings_json" = "1" ]; then
        flags="${flags:+$flags,}cfg"
    fi
    if [ "$has_settings_local" = "1" ]; then
        flags="${flags:+$flags,}local"
    fi

    # Project name = basename of root
    local name
    name=$(basename "$root")

    # Update exported state
    _CLAUDE_PS_ROOT="$root"
    _CLAUDE_PS_NAME="$name"
    _CLAUDE_PS_FLAGS="$flags"

    # Format the output segment
    _claude_format_segment "$name" "$flags"

    # Update cache
    _CLAUDE_PS_CACHED_PWD="$PWD"
}
