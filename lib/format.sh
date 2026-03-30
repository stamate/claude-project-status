#!/bin/sh
# claude-project-status: Output formatting
# Produces the prompt segment string with optional colors
# Supports zsh, bash, and plain text output modes

# Detect shell type for color escape syntax
_claude_detect_shell_type() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        printf "zsh"
    elif [ -n "${BASH_VERSION:-}" ]; then
        printf "bash"
    else
        printf "plain"
    fi
}

# Format the prompt segment
# Usage: _claude_format_segment "project-name" "md,cfg,local"
# Sets: _CLAUDE_PS_CACHED_OUTPUT
_claude_format_segment() {
    local name="$1"
    local flags="$2"

    # Determine color mode
    local use_color=1
    if [ "${CLAUDE_PROMPT_COLOR:-auto}" = "0" ]; then
        use_color=0
    fi

    local shell_type
    shell_type=$(_claude_detect_shell_type)

    # Check for custom format
    if [ -n "${CLAUDE_PROMPT_FORMAT:-}" ]; then
        _claude_format_custom "$name" "$flags" "${_CLAUDE_PS_ROOT:-}"
        return 0
    fi

    # Build the segment: [claude:name flags] or [claude:name]
    if [ "$use_color" = "0" ] || [ "$shell_type" = "plain" ]; then
        _claude_format_plain "$name" "$flags"
    elif [ "$shell_type" = "zsh" ]; then
        _claude_format_zsh "$name" "$flags"
    elif [ "$shell_type" = "bash" ]; then
        _claude_format_bash "$name" "$flags"
    else
        _claude_format_plain "$name" "$flags"
    fi
}

# Plain text output (no color escapes)
_claude_format_plain() {
    local name="$1"
    local flags="$2"

    if [ -n "$flags" ]; then
        _CLAUDE_PS_CACHED_OUTPUT="[claude:${name} ${flags}] "
    else
        _CLAUDE_PS_CACHED_OUTPUT="[claude:${name}] "
    fi
}

# Zsh color output using %F{color} escapes
_claude_format_zsh() {
    local name="$1"
    local flags="$2"

    local seg=""
    seg="%F{magenta}[%f"
    seg="${seg}%F{cyan}claude%f"
    seg="${seg}%F{magenta}:%f"
    seg="${seg}%F{white}${name}%f"

    if [ -n "$flags" ]; then
        seg="${seg} %F{yellow}${flags}%f"
    fi

    seg="${seg}%F{magenta}]%f "

    _CLAUDE_PS_CACHED_OUTPUT="$seg"
}

# Bash color output using \[\e[...m\] escapes
_claude_format_bash() {
    local name="$1"
    local flags="$2"

    local seg=""
    seg="\[\e[35m\][\[\e[36m\]claude\[\e[35m\]:\[\e[37m\]${name}\[\e[0m\]"

    if [ -n "$flags" ]; then
        seg="${seg} \[\e[33m\]${flags}\[\e[0m\]"
    fi

    seg="${seg}\[\e[35m\]]\[\e[0m\] "

    _CLAUDE_PS_CACHED_OUTPUT="$seg"
}

# Custom format string: %n=name, %f=flags, %r=root
_claude_format_custom() {
    local name="$1"
    local flags="$2"
    local root="$3"
    local fmt="${CLAUDE_PROMPT_FORMAT}"

    # Replace format tokens
    fmt=$(printf '%s' "$fmt" | sed "s/%n/$name/g; s/%f/$flags/g; s|%r|$root|g")

    # Strip trailing flag placeholder if flags are empty
    if [ -z "$flags" ]; then
        fmt=$(printf '%s' "$fmt" | sed 's/  */ /g; s/ \]/]/g')
    fi

    _CLAUDE_PS_CACHED_OUTPUT="${fmt} "
}
