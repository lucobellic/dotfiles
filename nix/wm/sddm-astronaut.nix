{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.programs.sddmAstronaut;

  # Build the sddm-astronaut package from latest source, overriding the
  # nixpkgs version which is pinned to an older unstable snapshot.
  sddmAstronautPackage = pkgs.sddm-astronaut.overrideAttrs (oldAttrs: {
    version = "1.3";
    src = pkgs.fetchFromGitHub {
      owner = "Keyitdev";
      repo = "sddm-astronaut-theme";
      rev = "d73842c761f7d7859f3bdd80e4360f09180fad41";
      hash = "sha256-+94WVxOWfVhIEiVNWwnNBRmN+d1kbZCIF10Gjorea9M=";
    };
  });

  # Build the configured package with the chosen embedded theme and any
  # user-supplied theme config overrides.
  sddmAstronautConfigured = sddmAstronautPackage.override (
    {
      embeddedTheme = cfg.embeddedTheme;
    }
    // lib.optionalAttrs (cfg.themeConfig != null) {
      themeConfig = cfg.themeConfig;
    }
  );

  themeSourcePath = "${sddmAstronautConfigured}/share/sddm/themes/sddm-astronaut-theme";

  sddmUpdateCommand = "sudo ~/.local/bin/update-sddm-config --theme-source ${themeSourcePath}";

  compileSDDMScript = pkgs.writeShellScript "compile-sddm-script" ''
    set -e

    export PATH="$HOME/.cargo/bin:$HOME/.nix-profile/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

    if ! command -v cargo >/dev/null 2>&1; then
      echo -e "\033[1;33m⚠ cargo not found, skipping SDDM script compilation\033[0m"
      exit 0
    fi

    if ! cargo -Zscript --help >/dev/null 2>&1; then
      echo -e "\033[1;33m⚠ cargo -Zscript not available, skipping SDDM script compilation\033[0m"
      exit 0
    fi

    CACHE_DIR="$HOME/.cache/rust-scripts"
    mkdir -p "$CACHE_DIR"

    SCRIPT_PATH="${config.home.homeDirectory}/.config/home-manager/config/sddm/update-sddm-config.rs"

    if [ -f "$SCRIPT_PATH" ]; then
      echo -e "\033[1;34m🦀 Compiling SDDM Rust script...\033[0m"

      CACHE_FILE="$CACHE_DIR/update-sddm-config.hash"
      CURRENT_HASH="$(sha256sum "$SCRIPT_PATH" | cut -d' ' -f1)"

      if [ -f "$CACHE_FILE" ] && [ "$(cat "$CACHE_FILE")" = "$CURRENT_HASH" ]; then
        echo -e "  \033[1;90m○\033[0m update-sddm-config (cached)"
      else
        if cargo build -Zscript --manifest-path "$SCRIPT_PATH" >/dev/null 2>&1; then
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
  options.programs.sddmAstronaut = {
    enable = lib.mkEnableOption "sddm-astronaut theme";

    embeddedTheme = lib.mkOption {
      type = lib.types.str;
      default = "astronaut";
      example = "cyberpunk";
      description = ''
        The built-in theme variant to use. Available themes:
        astronaut, black_hole, cyberpunk, hyprland_kath,
        jake_the_dog, japanese_aesthetic, pixel_sakura,
        pixel_sakura_static, post-apocalyptic_hacker, purple_leaves.
      '';
    };

    themeConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      example = lib.literalExpression ''
        {
          ScreenWidth = 1920;
          ScreenHeight = 1080;
          FullBlur = true;
          BlurMax = 64;
        }
      '';
      description = ''
        Attribute set of theme configuration overrides. These are written
        to the theme's .conf.user file. See the upstream theme .conf files
        for available options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Install the configured theme package
    home.packages = [ sddmAstronautConfigured ];

    # Symlink the wrapper script to ~/.local/bin so it can be called with sudo
    home.file.".local/bin/update-sddm-config" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/config/sddm/update-sddm-config.sh";
    };

    # Compile the SDDM Rust script after symlinks are created
    home.activation.compileSDDMScript = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
      ${compileSDDMScript}
    '';

    # Log the command needed to apply the theme to the system SDDM
    home.activation.logSddmAstronautUpdate = lib.hm.dag.entryAfter [ "compileSDDMScript" ] ''
      if [[ -v oldGenPath && -v newGenPath ]]; then
        OLD_THEME=$(readlink -f "$oldGenPath/home-path/share/sddm/themes/sddm-astronaut-theme" 2>/dev/null || echo "")
        NEW_THEME=$(readlink -f "$newGenPath/home-path/share/sddm/themes/sddm-astronaut-theme" 2>/dev/null || echo "")

        if [[ "$OLD_THEME" != "$NEW_THEME" && -n "$NEW_THEME" ]]; then
          echo -e "\033[1;32m"
          echo -e "sddm-astronaut theme updated. Perform update:"
          echo -e "\t${sddmUpdateCommand}"
          echo -e "\033[0m"
        fi
      else
        # First installation
        echo -e "\033[1;32m"
        echo -e "sddm-astronaut theme installed. Perform initial setup:"
        echo -e "\t${sddmUpdateCommand}"
        echo -e "\033[0m"
      fi
    '';
  };
}
