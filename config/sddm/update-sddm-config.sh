#!/usr/bin/env bash
set -e

# Detect the actual user's home directory (even when running with sudo)
# When running with sudo, $HOME points to /root, so we need to get the original user's home
if [ -n "$SUDO_USER" ]; then
  # Running with sudo - get the original user's home directory
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  # Running as regular user
  USER_HOME="$HOME"
fi

# Set up PATH to include common cargo locations from the actual user's home
# This is needed when running with sudo, which doesn't preserve user PATH
export PATH="$USER_HOME/.cargo/bin:$USER_HOME/.nix-profile/bin:$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Get the Rust script path - it's in the same directory as this wrapper script
# Since this wrapper is symlinked, we construct the path from the user's home
RUST_SCRIPT="${USER_HOME}/.config/home-manager/config/sddm/update-sddm-config.rs"

# Verify the Rust script exists
if [ ! -f "$RUST_SCRIPT" ]; then
  echo "Error: Rust script not found at $RUST_SCRIPT" >&2
  exit 1
fi

# Check if cargo is available
if ! command -v cargo >/dev/null 2>&1; then
  echo "Error: cargo not found in PATH" >&2
  echo "Please ensure cargo is installed and available in one of these locations:" >&2
  echo "  - $USER_HOME/.cargo/bin" >&2
  echo "  - $USER_HOME/.nix-profile/bin" >&2
  echo "  - /usr/local/bin" >&2
  echo "  - /usr/bin" >&2
  exit 1
fi

# Check if cargo -Zscript is available (requires nightly)
if ! cargo -Zscript --help >/dev/null 2>&1; then
  echo "Error: cargo -Zscript not available. This requires a nightly Rust toolchain." >&2
  echo "Install with: rustup toolchain install nightly" >&2
  exit 1
fi

# Execute the Rust script with all passed arguments
exec cargo -Zscript "$RUST_SCRIPT" "$@"
