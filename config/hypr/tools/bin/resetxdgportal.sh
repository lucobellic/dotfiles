#!/usr/bin/env bash

set -euo pipefail

# Properly restart xdg-desktop-portal implementations using systemd --user when available.
# This avoids DBus name conflicts by letting systemd manage the process lifecycle.

services=(
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  xdg-desktop-portal-gnome
  xdg-desktop-portal-kde
  xdg-desktop-portal-lxqt
  xdg-desktop-portal-wlr
  xdg-desktop-portal
  xdg-document-portal
)

restart_via_systemd() {
  local name="$1"
  if command -v systemctl >/dev/null 2>&1; then
    # Try restart first, then start if restart fails (unit might be static or not running yet)
    systemctl --user restart "${name}.service" >/dev/null 2>&1 || systemctl --user start "${name}.service" >/dev/null 2>&1 || return 1
    return 0
  fi
  return 1
}

# Fallback to killing/starting the binary directly if systemd user manager is not available
start_binary_fallback() {
  local name="$1"
  # kill any existing processes for this exact binary name
  pkill -u "$(id -u)" -x "${name}" >/dev/null 2>&1 || true

  # search common libexec locations for the binary and launch it in background
  for dir in /run/current-system/sw/libexec /usr/libexec /usr/lib /usr/local/libexec; do
    if [ -x "${dir}/${name}" ]; then
      "${dir}/${name}" &
      return 0
    fi
  done
  return 1
}

for s in "${services[@]}"; do
  if restart_via_systemd "$s"; then
    printf "Restarted %s via systemd --user\n" "$s"
  else
    if start_binary_fallback "$s"; then
      printf "Started %s via fallback binary\n" "$s"
    else
      printf "No unit/binary found for %s; skipping\n" "$s"
    fi
  fi
done

exit 0
