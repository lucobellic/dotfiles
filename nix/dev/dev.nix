{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    (python3.withPackages
      (ps: with ps; [ requests numpy pandas pyyaml typer scapy awscli uv ]))

    rustup

    go

    gopls
    delve
  ];

  # Create symlink for xdg-open-host-listener script
  home.file."bin/xdg-open-host-listener".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.config/home-manager/config/xdg-open-host-listener.sh";

  programs.lazydocker = { enable = true; };

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
      work = { target = "vaults/work"; };
      personal = { target = "vaults/personal"; };
    };
  };

  # Systemd service for xdg-open host listener
  systemd.user.services.xdg-open-host-listener = {
    Unit = {
      Description = "XDG Open Host Listener for Container Communication";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart =
        "${pkgs.bash}/bin/bash ${config.home.homeDirectory}/bin/xdg-open-host-listener";
      Restart = "on-failure";
      RestartSec = 5;
      # Import environment variables needed for GUI applications
      Environment = [
        "PATH=${pkgs.xdg-utils}/bin:${pkgs.firefox}/bin:${config.home.homeDirectory}/.nix-profile/bin:/run/current-system/sw/bin"
      ];
    };

    Install = { WantedBy = [ "default.target" ]; };
  };
}
