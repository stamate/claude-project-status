#!/bin/sh
# claude-project-status: Uninstaller (convenience wrapper)
set -e
exec "$(cd "$(dirname "$0")" && pwd)/install.sh" --uninstall
