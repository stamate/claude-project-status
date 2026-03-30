#!/usr/bin/env zsh
# claude-project-status: Zsh integration
# Sources the core detection library and hooks into the prompt via precmd.
# Auto-patches PROMPT (or RPROMPT for Warp) to insert the Claude project segment.
#
# Usage: Add to ~/.zshrc (after oh-my-zsh source line):
#   source /path/to/claude_project_status/integrations/zsh.zsh

# Guard against double-sourcing
if (( ${+functions[_claude_project_precmd]} )); then
    return 0
fi

# Resolve the real path to this script (works with symlinks)
local _cps_dir="${0:A:h}/.."

# Source core libraries
source "${_cps_dir}/lib/format.sh"
source "${_cps_dir}/lib/detect.sh"

# The prompt variable — parallel to vcs_info_msg_0_
typeset -g claude_project_msg_0_=""

# Detect Warp terminal with its own prompt rendering
# When WARP_HONOR_PS1=0 (default), Warp ignores PROMPT and renders its own.
# In that case we use RPROMPT instead, which Warp does display.
typeset -g _CLAUDE_PS_USE_RPROMPT=0
if [[ "$TERM_PROGRAM" == "WarpTerminal" && "${WARP_HONOR_PS1:-0}" == "0" ]]; then
    _CLAUDE_PS_USE_RPROMPT=1
fi

# Save the user's original RPROMPT so we can prepend our segment without
# destroying existing content (clock, battery, etc.)
typeset -g _CLAUDE_PS_ORIG_RPROMPT="${RPROMPT:-}"

# precmd hook: runs before every prompt render
_claude_project_precmd() {
    _claude_detect_project
    claude_project_msg_0_="$_CLAUDE_PS_CACHED_OUTPUT"

    # Warp RPROMPT mode: prepend our segment to the user's original RPROMPT
    if (( _CLAUDE_PS_USE_RPROMPT )); then
        if [[ -n "$_CLAUDE_PS_CACHED_OUTPUT" ]]; then
            RPROMPT="${claude_project_msg_0_}${_CLAUDE_PS_ORIG_RPROMPT}"
        else
            RPROMPT="${_CLAUDE_PS_ORIG_RPROMPT}"
        fi
    fi
}

# Register the hook
autoload -U add-zsh-hook
add-zsh-hook precmd _claude_project_precmd

# Prompt patching: only needed when NOT using RPROMPT mode
if (( ! _CLAUDE_PS_USE_RPROMPT )); then
    # One-time PROMPT patching at source time
    # Strategy: insert ${claude_project_msg_0_} after ${vcs_info_msg_0_} if present,
    # otherwise insert before the trailing prompt symbol ($ or #)
    #
    # Note: zsh ${var/pat/rep} doesn't support quoting inside the expression,
    # so we use variables to hold literal pattern/replacement strings.
    {
        local _cps_vcs='${vcs_info_msg_0_}'
        local _cps_claude='${claude_project_msg_0_}'
        local _cps_sym='%(!.#.$)'

        if [[ "$PROMPT" == *'${vcs_info_msg_0_}'* ]]; then
            # Insert right after vcs_info segment
            PROMPT="${PROMPT/${_cps_vcs}/${_cps_vcs}${_cps_claude}}"
        elif [[ "$PROMPT" == *'%(!.#.$)'* ]]; then
            # gentoo-style prompt without vcs_info — insert before the prompt symbol
            PROMPT="${PROMPT/${_cps_sym}/${_cps_claude}${_cps_sym}}"
        elif [[ "$PROMPT" == *'$ '* ]]; then
            # Generic prompt with $ — insert before it
            local _cps_dollar='$ '
            PROMPT="${PROMPT/${_cps_dollar}/${_cps_claude}${_cps_dollar}}"
        else
            # Fallback: append to the end
            PROMPT="${PROMPT}${_cps_claude}"
        fi
    }
fi
