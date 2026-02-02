{
  pkgs,
  config,
  lib,
  ...
}:

let
  # Fetch the SilentSDDM flake
  silentSDDMFlake = builtins.getFlake "github:uiriansan/SilentSDDM";

  # Get the default package for the current system
  silentSDDMPackage = silentSDDMFlake.packages.${pkgs.stdenv.hostPlatform.system}.default;

  cfg = config.programs.silentSDDM;

  # Build the configured package with overrides
  silentSDDMConfigured = cfg.package.override {
    theme = cfg.theme;
    extraBackgrounds = lib.attrValues cfg.backgrounds;
    theme-overrides = cfg.settings;
  };

  themeSourcePath = "${silentSDDMConfigured}/share/sddm/themes/silent";

  # Command to run (will be logged) - user runs with sudo
  # The Rust script will find the theme source automatically, or it can be passed via --theme-source
  sddmUpdateCommand = "sudo ~/.local/bin/update-sddm-config --theme-source ${themeSourcePath}";

  # Script to compile the SDDM Rust script
  compileSDDMScript = pkgs.writeShellScript "compile-sddm-script" ''
    set -e

    # Ensure PATH includes common locations for cargo/rustup
    export PATH="$HOME/.cargo/bin:$HOME/.nix-profile/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

    # Find cargo
    if ! command -v cargo >/dev/null 2>&1; then
      echo -e "\033[1;33m⚠ cargo not found, skipping SDDM script compilation\033[0m"
      exit 0
    fi

    # Check if nightly toolchain is available (cargo -Zscript requires nightly)
    if ! cargo -Zscript --help >/dev/null 2>&1; then
      echo -e "\033[1;33m⚠ cargo -Zscript not available, skipping SDDM script compilation\033[0m"
      exit 0
    fi

    # Directory to track compiled script hashes
    CACHE_DIR="$HOME/.cache/rust-scripts"
    mkdir -p "$CACHE_DIR"

    SCRIPT_PATH="${config.home.homeDirectory}/.config/home-manager/config/sddm/update-sddm-config.rs"

    if [ -f "$SCRIPT_PATH" ]; then
      echo -e "\033[1;34m🦀 Compiling SDDM Rust script...\033[0m"

      CACHE_FILE="$CACHE_DIR/update-sddm-config.hash"
      CURRENT_HASH="$(sha256sum "$SCRIPT_PATH" | cut -d' ' -f1)"

      # Check if we already compiled this exact version
      if [ -f "$CACHE_FILE" ] && [ "$(cat "$CACHE_FILE")" = "$CURRENT_HASH" ]; then
        echo -e "  \033[1;90m○\033[0m update-sddm-config (cached)"
      else
        if cargo build -Zscript --manifest-path "$SCRIPT_PATH" >/dev/null 2>&1; then
          # Store the hash to track this version
          echo "$CURRENT_HASH" > "$CACHE_FILE"
          echo -e "  \033[1;32m✓\033[0m update-sddm-config"
        else
          echo -e "  \033[1;31m✗\033[0m update-sddm-config (compilation failed)"
        fi
      fi
    fi
  '';
in
{
  options.programs.silentSDDM = {
    enable = lib.mkEnableOption "silentSDDM theme";

    package = lib.mkOption {
      type = lib.types.package;
      default = silentSDDMPackage;
      description = "silentSDDM package to use";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "rei";
      example = "ken";
      description = "the builtin theme to use";
    };

    backgrounds = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.package);
      default = { };
      example = lib.literalExpression ''
        {
          reze = pkgs.fetchurl {
            name = "hana.jpg";
            url = "https://example.com/image.jpg";
            hash = "sha256-...";
          };
          kokomi = "/images/kokomi/kokomi96024.png";
        }
      '';
      description = "attrset containing drvs or absolute path to wallpapers";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      example = lib.literalExpression ''
        {
          "LoginScreen.LoginArea.Avatar" = {
            shape = "circle";
            active-border-color = "#ffcfce";
          };
          "LoginScreen" = {
            background = "hana.jpg";
          };
          "LockScreen" = {
            background = "kokomi96024.png";
          };
        }
      '';
      description = ''
        attrset containing silent sddm configuration
        these settings overwrite the defaults set by the `theme`
        see https://github.com/uiriansan/SilentSDDM/wiki/Options
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Install the configured SilentSDDM theme package
    home.packages = [
      silentSDDMConfigured
      silentSDDMConfigured.test
    ];

    # Create symlink to the wrapper script in .local/bin
    # The wrapper script sets up PATH and executes the Rust script
    home.file.".local/bin/update-sddm-config" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/config/sddm/update-sddm-config.sh";
    };

    # Compile the SDDM Rust script after symlinks are created
    home.activation.compileSDDMScript = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
      ${compileSDDMScript}
    '';

    # Log the command during Home Manager activation
    home.activation.logSDDMUpdateCommand = lib.hm.dag.entryAfter [ "compileSDDMScript" ] ''
      echo -e "\033[1;32m"
      echo -e "Perform SilentSDDM update:"
      echo -e "\t${sddmUpdateCommand}"
      echo -e "\033[0m"
    '';
  };
}
