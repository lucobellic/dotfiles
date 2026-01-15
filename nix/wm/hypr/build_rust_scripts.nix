{
  pkgs,
  lib,
  ...
}:
let
  # Rust script paths for precompilation
  binScripts = [
    "associate_window_to_workspace.rs"
    "keybinds_hint.rs"
    "lid_monitor_handler.rs"
    "open_eww_workspaces.rs"
    "select_wallpaper.rs"
    "set_wallpaper.rs"
    "setup_monitors.rs"
    "terminal-dropdown.rs"
  ];

  ewwScripts = [
    "audio.rs"
    "battery-usage.rs"
    "cpu-cores.rs"
    "cpu-usage.rs"
    "disk-usage.rs"
    "gpu-usage.rs"
    "hyprsunset.rs"
    "integrated-gpu-usage.rs"
    "ram-usage.rs"
  ];

  # Script to compile Rust scripts with progress indication
  compileRustScripts = pkgs.writeShellScript "compile-rust-scripts" ''
    set -e

    # Ensure PATH includes common locations for cargo/rustup
    export PATH="$HOME/.cargo/bin:$HOME/.nix-profile/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

    # Find cargo
    if ! command -v cargo >/dev/null 2>&1; then
      echo -e "\033[1;33m⚠ cargo not found, skipping Rust script compilation\033[0m"
      exit 0
    fi

    # Check if nightly toolchain is available (cargo -Zscript requires nightly)
    if ! cargo -Zscript --help >/dev/null 2>&1; then
      echo -e "\033[1;33m⚠ cargo -Zscript not available, skipping Rust script compilation\033[0m"
      exit 0
    fi

    compile_script() {
      local script="$1"
      local name="$(basename "$script" .rs)"

      # Use cargo build to produce the cached binary (not just check)
      # This populates the script cache so subsequent runs don't recompile
      if cargo build -Zscript --manifest-path "$script" >/dev/null 2>&1; then
        echo -e "  \033[1;32m✓\033[0m $name"
        return 0
      else
        echo -e "  \033[1;31m✗\033[0m $name (compilation failed)"
        return 1
      fi
    }

    echo ""
    echo -e "\033[1;34m󰭻 Compiling Rust scripts...\033[0m"

    # Compile bin scripts
    BIN_DIR="$HOME/.local/share/bin"
    if [ -d "$BIN_DIR" ]; then
      echo -e "\033[1;36m  ~/.local/share/bin:\033[0m"
      for script in ${lib.concatStringsSep " " binScripts}; do
        if [ -f "$BIN_DIR/$script" ]; then
          compile_script "$BIN_DIR/$script" || true
        fi
      done
    fi

    # Compile eww scripts
    EWW_DIR="$HOME/.config/eww/scripts"
    if [ -d "$EWW_DIR" ]; then
      echo -e "\033[1;36m  ~/.config/eww/scripts:\033[0m"
      for script in ${lib.concatStringsSep " " ewwScripts}; do
        if [ -f "$EWW_DIR/$script" ]; then
          compile_script "$EWW_DIR/$script" || true
        fi
      done
    fi

    echo -e "\033[1;32m✓ Rust script compilation complete\033[0m"
    echo ""
  '';
in
{
  # Compile Rust scripts after symlinks are created
  home.activation.compileRustScripts = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
    ${compileRustScripts}
  '';
}
