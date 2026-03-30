#!/usr/bin/env fish
# claude-project-status: Fish shell integration
#
# Usage: Add to ~/.config/fish/config.fish:
#   source /path/to/claude_project_status/integrations/fish.fish
#
# Or copy this file to ~/.config/fish/conf.d/claude_project_status.fish

# Cache variables
set -g _CLAUDE_PS_CACHED_PWD ""
set -g _CLAUDE_PS_CACHED_OUTPUT ""
set -g _CLAUDE_PS_ROOT ""
set -g _CLAUDE_PS_NAME ""
set -g _CLAUDE_PS_FLAGS ""

function _claude_detect_project_fish
    # Kill switch
    if test "$CLAUDE_PROMPT_DISABLE" = "1"
        set -g _CLAUDE_PS_CACHED_OUTPUT ""
        return 0
    end

    # Cache hit
    if test "$_CLAUDE_PS_CACHED_PWD" = "$PWD"
        return 0
    end

    set -l root ""
    set -l has_claude_md 0
    set -l has_settings_json 0
    set -l has_settings_local 0

    if test -n "$CLAUDE_PROJECT_ROOT"
        if test -d "$CLAUDE_PROJECT_ROOT"
            set root "$CLAUDE_PROJECT_ROOT"
        end
    else
        set -l dir "$PWD"
        while true
            if test -d "$dir/.claude"
                set root "$dir"
                break
            end
            if test -f "$dir/CLAUDE.md"
                set root "$dir"
                break
            end
            if test "$dir" = "/"
                break
            end
            set dir (dirname "$dir")
        end
    end

    # Exclude $HOME
    if test "$root" = "$HOME"
        set root ""
    end

    if test -z "$root"
        set -g _CLAUDE_PS_CACHED_PWD "$PWD"
        set -g _CLAUDE_PS_CACHED_OUTPUT ""
        set -g _CLAUDE_PS_ROOT ""
        set -g _CLAUDE_PS_NAME ""
        set -g _CLAUDE_PS_FLAGS ""
        return 0
    end

    test -f "$root/CLAUDE.md"; and set has_claude_md 1
    test -f "$root/.claude/settings.json"; and set has_settings_json 1
    test -f "$root/.claude/settings.local.json"; and set has_settings_local 1

    set -l flags ""
    test $has_claude_md -eq 1; and set flags "md"
    if test $has_settings_json -eq 1
        if test -n "$flags"
            set flags "$flags,cfg"
        else
            set flags "cfg"
        end
    end
    if test $has_settings_local -eq 1
        if test -n "$flags"
            set flags "$flags,local"
        else
            set flags "local"
        end
    end

    set -l name (basename "$root")
    set -g _CLAUDE_PS_ROOT "$root"
    set -g _CLAUDE_PS_NAME "$name"
    set -g _CLAUDE_PS_FLAGS "$flags"

    # Format with Fish color codes
    if test -n "$flags"
        set -g _CLAUDE_PS_CACHED_OUTPUT (set_color magenta)"["(set_color cyan)"claude"(set_color magenta)":"(set_color white)"$name"(set_color normal)" "(set_color yellow)"$flags"(set_color magenta)"]"(set_color normal)" "
    else
        set -g _CLAUDE_PS_CACHED_OUTPUT (set_color magenta)"["(set_color cyan)"claude"(set_color magenta)":"(set_color white)"$name"(set_color magenta)"]"(set_color normal)" "
    end

    set -g _CLAUDE_PS_CACHED_PWD "$PWD"
end

# Helper function to call from fish_prompt
function claude_project_segment
    _claude_detect_project_fish
    echo -n "$_CLAUDE_PS_CACHED_OUTPUT"
end
