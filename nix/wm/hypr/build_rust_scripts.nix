{
  pkgs,
  lib,
  ...
}:
let
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

  # Script to build the Rust workspace and compile eww scripts
  compileRustScripts = pkgs.writeShellScript "compile-rust-scripts" ''
    set -e

    # Ensure PATH includes common locations for cargo/rustup
    export PATH="$HOME/.cargo/bin:$HOME/.nix-profile/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

    # Find cargo
    if ! command -v cargo >/dev/null 2>&1; then
      echo -e "\033[1;33m⚠ cargo not found, skipping Rust compilation\033[0m"
      exit 0
    fi

    echo ""
    echo -e "\033[1;34m🦀 Building Rust workspace...\033[0m"

    # Build the hypr-tools workspace (binaries land in target/release/ and are used directly)
    WORKSPACE_DIR="$HOME/.config/home-manager/config/hypr/tools"

    if [ -f "$WORKSPACE_DIR/Cargo.toml" ]; then
      echo -e "\033[1;36m  $WORKSPACE_DIR\033[0m"

      if cargo build --release --manifest-path "$WORKSPACE_DIR/Cargo.toml" 2>&1; then
        echo -e "\033[1;32m  ✓ Workspace build succeeded\033[0m"
        echo -e "  Binaries available at: $WORKSPACE_DIR/target/release/"
      else
        echo -e "\033[1;31m  ✗ Workspace build failed\033[0m"
      fi
    else
      echo -e "\033[1;33m⚠ Workspace Cargo.toml not found at $WORKSPACE_DIR\033[0m"
    fi

    # Compile eww scripts (still using cargo -Zscript)
    if cargo -Zscript --help >/dev/null 2>&1; then
      CACHE_DIR="$HOME/.cache/rust-scripts"
      mkdir -p "$CACHE_DIR"

      compile_script() {
        local script="$1"
        local name="$(basename "$script" .rs)"
        local cache_file="$CACHE_DIR/$name.storepath"

        local resolved_path
        if [ -L "$script" ]; then
          resolved_path="$(readlink -f "$script")"
        else
          resolved_path="$script"
        fi

        if [ -f "$cache_file" ] && [ "$(cat "$cache_file")" = "$resolved_path" ]; then
          echo -e "  \033[1;90m○\033[0m $name (cached)"
          return 0
        fi

        if cargo build -Zscript --manifest-path "$script" >/dev/null 2>&1; then
          echo "$resolved_path" > "$cache_file"
          echo -e "  \033[1;32m✓\033[0m $name"
          return 0
        else
          echo -e "  \033[1;31m✗\033[0m $name (compilation failed)"
          return 1
        fi
      }

      EWW_DIR="$HOME/.config/eww/scripts"
      if [ -d "$EWW_DIR" ]; then
        echo -e "\033[1;36m  ~/.config/eww/scripts:\033[0m"
        for script in ${lib.concatStringsSep " " ewwScripts}; do
          if [ -f "$EWW_DIR/$script" ]; then
            compile_script "$EWW_DIR/$script" || true
          fi
        done
      fi
    fi

    echo -e "\033[1;32m✓ Rust compilation complete\033[0m"
    echo ""
  '';
in
{
  # Build Rust workspace after symlinks are created.
  # Compiled binaries live at:
  #   ~/.config/home-manager/config/hypr/tools/target/release/<name>
  # They are referenced directly via $scrPath in hyprland.conf — no install step needed.
  home.activation.compileRustScripts = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
    ${compileRustScripts}
  '';
}
