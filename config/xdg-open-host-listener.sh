#!/bin/bash
# xdg-open host listener script
# This script should be run on the HOST machine to handle xdg-open calls from the container

# Use a fixed location that can be easily mounted to containers
PIPE_DIR="$HOME/.local/share"
PIPE="$PIPE_DIR/xdg-open-pipe"

# Ensure directory exists
mkdir -p "$PIPE_DIR"

# Create named pipe only if it doesn't exist
if [[ ! -p "$PIPE" ]]; then
  mkfifo "$PIPE"
  chmod 664 "$PIPE"
fi

echo "xdg-open listener started. Waiting for requests from container..."
echo "Press Ctrl+C to stop."

# Cleanup on exit
cleanup() {
  echo "Cleaning up..."
  rm -f "$PIPE"
  exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Listen for requests
while true; do
  # Note: 'read' from a named pipe is blocking and waits for data (no active polling)
  # Use a while-read loop with input redirection to avoid stdin issues
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Opening: $line"
      # Use host's xdg-open to open the URL/file
      xdg-open "$line" &
    fi
  done <"$PIPE"
  # If the pipe is closed/broken, wait a bit before retrying
  sleep 1
done
