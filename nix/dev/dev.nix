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
        jinja2
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

    nodejs
    yarn
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

}
