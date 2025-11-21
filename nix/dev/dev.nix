{ pkgs, lib, ... }:

{
  imports = [
    ./cocoindex.nix
  ];

  home.packages = with pkgs; [
    (python3.withPackages
      (ps: with ps; [ requests numpy pandas pyyaml typer scapy awscli uv ]))

    rustup

    go
    gopls
    delve
  ];

  home.activation.setupRustup = lib.hm.dag.entryAfter ["installPackages"] ''
    if command -v rustup >/dev/null 2>&1; then
      run echo "Setting up Rust toolchain..."

      # Install stable toolchain and set as default
      run rustup default stable

      # Install rust-analyzer component
      run rustup component add rust-analyzer

      # Install musl target
      run rustup target add x86_64-unknown-linux-musl

      run echo "Rust toolchain setup complete"
    fi
  '';

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
      work = { target = "vaults/work"; };
      personal = { target = "vaults/personal"; };
    };
  };
}
