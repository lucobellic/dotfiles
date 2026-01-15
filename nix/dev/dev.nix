{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    nixfmt-rfc-style

    (python3.withPackages (
      ps: with ps; [
        requests
        numpy
        pandas
        pyyaml
        typer
        scapy
        awscli
        uv
      ]
    ))

    # Rust toolchain with stable and nightly
    (rust-bin.selectLatestNightlyWith (
      toolchain:
      toolchain.default.override {
        extensions = [
          "rust-src"
          "rust-analyzer"
        ];
      }
    ))

    go

    gopls
    delve
  ];

  # Create symlink for xdg-open-host-listener script
  home.file.".local/bin/xdg-open-host-listener".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/config/xdg-open-host-listener.sh";

  programs.lazydocker = {
    enable = true;
  };

  programs.obsidian = {
    enable = true;
    defaultSettings = {
      app = {
        vimMode = true;
        file-explorer = true;
      };
      appearance = {
        cssTheme = "Catppuccin";
        textFontFamily = "DMMono Nerd Font";
        monospaceFontFamily = "DMMono Nerd Font";
        baseFontSize = 12;
      };
      communityPlugins = [ ];
      corePlugins = [
        "file-explorer"
        "global-search"
        "switcher"
        "graph"
        "backlink"
        "canvas"
        "outgoing-link"
        "tag-pane"
        "properties"
        "page-preview"
        "daily-notes"
        "templates"
        "note-composer"
        "command-palette"
        "slash-command"
        "editor-status"
        "bookmarks"
        "markdown-importer"
        "zk-prefixer"
        "random-note"
        "outline"
        "word-count"
        "slides"
        "audio-recorder"
        "workspaces"
        "file-recovery"
        "publish"
        "sync"
      ];
      hotkeys = { };
      themes = [ ];
    };
    vaults = {
      work = {
        target = "vaults/work";
      };
      personal = {
        target = "vaults/personal";
      };
    };
  };

  # Systemd service for xdg-open host listener
  systemd.user.services.xdg-open-host-listener = {
    Unit = {
      Description = "XDG Open Host Listener for Container Communication";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash ${config.home.homeDirectory}/.local/bin/xdg-open-host-listener";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "PATH=${pkgs.coreutils}/bin:${pkgs.xdg-utils}/bin:${pkgs.firefox}/bin:${config.home.homeDirectory}/.nix-profile/bin:/run/current-system/sw/bin"
      ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
