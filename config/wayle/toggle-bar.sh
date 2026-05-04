#!/usr/bin/env bash
set -euo pipefail
# Simple toggle script: flip all occurrences of "show = true" <-> "show = false"
# in the Wayle runtime config file.

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/wayle/runtime.toml"
mkdir -p "$(dirname "$CONFIG")"

if [ ! -f "$CONFIG" ]; then
  cat > "$CONFIG" <<'EOF'
[[bar.layout]]
monitor = "*"
show = true
left = []
center = []
right = []
EOF
fi

# If any literal 'show = true' exists, replace all such lines with 'show = false',
# otherwise replace 'show = false' with 'show = true'. This is a simple find/replace
# approach (line-oriented) and intentionally minimal.
if grep -qE '^[[:space:]]*show[[:space:]]*=[[:space:]]*true\b' "$CONFIG"; then
  sed -E 's/^([[:space:]]*)show[[:space:]]*=[[:space:]]*true\b/\1show = false/' "$CONFIG" > "$CONFIG.tmp" && mv -- "$CONFIG.tmp" "$CONFIG"
  echo "Toggled: show -> false"
else
  sed -E 's/^([[:space:]]*)show[[:space:]]*=[[:space:]]*false\b/\1show = true/' "$CONFIG" > "$CONFIG.tmp" && mv -- "$CONFIG.tmp" "$CONFIG"
  echo "Toggled: show -> true"
fi

chmod 644 "$CONFIG"
