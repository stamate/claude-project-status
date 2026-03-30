#!/bin/sh
# claude-project-status: Path encoding
# Encodes filesystem paths to match Claude Code's internal project directory naming
# Convention: replace / . _ with -
# Example: /Users/c/lab/metale → -Users-c-lab-metale

# Encode a path for lookup in ~/.claude/projects/
# Usage: _claude_encode_path "/Users/c/lab/metale"
# Output: printed to stdout
_claude_encode_path() {
    printf '%s' "$1" | tr '/._' '---'
}

# Count sessions for a project by checking ~/.claude/projects/{encoded}/
# Usage: _claude_count_sessions "/Users/c/lab/metale"
# Output: session count printed to stdout
_claude_count_sessions() {
    local project_root="$1"
    local claude_home="${CLAUDE_HOME:-$HOME/.claude}"
    local encoded
    encoded=$(_claude_encode_path "$project_root")
    local projects_dir="${claude_home}/projects/${encoded}"

    if [ ! -d "$projects_dir" ]; then
        printf '0'
        return 0
    fi

    # Count .jsonl files (each is a session transcript)
    local count=0
    for f in "$projects_dir"/*.jsonl; do
        [ -f "$f" ] && count=$((count + 1))
    done
    printf '%d' "$count"
}
