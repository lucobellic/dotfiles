#!/bin/sh
# Usage: nvim-remote-edit.sh <filename> [line]
# Opens <filename> in the current nvim buffer (not a new tab).
# Falls back to a plain nvim invocation when not inside a nvim session.
FILE="$1"
LINE="$2"

if [ -z "$NVIM" ]; then
	if [ -n "$LINE" ]; then
		nvim +"$LINE" -- "$FILE"
	else
		nvim -- "$FILE"
	fi
else
	# Hide the term.core popup (lazygit floats inside it), then open the file.
	# Without the hide() call the popup stays focused and immediately steals
	# focus back, making the newly opened buffer appear to "flash" and revert.
	nvim --server "$NVIM" --remote-send "<C-\\><C-N>:lua require('term.core').hide()<CR>"
	nvim --server "$NVIM" --remote "$FILE"
	if [ -n "$LINE" ]; then
		nvim --server "$NVIM" --remote-send ":${LINE}<CR>"
	fi
fi
