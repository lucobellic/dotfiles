{ pkgs, config, ... }:

{

  home.packages = with pkgs; [ lazygit ];

  xdg.configFile.lazygit.source =
    config.lib.file.mkOutOfStoreSymlink ../config/lazygit;

  programs = {
    git = {
      enable = true;
      settings = {
        rebase = { autoStash = true; };
        rerere = { enabled = true; };
        pull = { rebase = true; };
        push = { autoSetupRemote = true; };
      };
    };

    delta = {
      enable = true;
      options = {
        features = "ayu-gloom";
        ayu-gloom = {
          dark = true;
          commit-style = "normal";
          commit-decoration-style = "ul";
          file-decoration-style = "box blue";
          file-style = "blue";
          file-modified-label = "";
          hunk-header-style = "omit";
          line-numbers = true;
          line-numbers-left-style = "#4D5566";
          line-numbers-minus-style = "red";
          line-numbers-plus-style = "green";
          line-numbers-right-style = "#4D5566";
          line-numbers-zero-style = "#4D5566";
          minus-emph-style = "black red";
          minus-style = "red";
          plus-emph-style = "black green";
          plus-style = "green";
          zero-style = "#4D5566";
          syntax-theme = "none";
          merge-conflict-begin-symbol = "-";
          merge-conflict-end-symbol = "─";
          merge-conflict-ours-diff-header-style = "purple";
          merge-conflict-ours-diff-header-decoration-style = "ul";
          merge-conflict-theirs-diff-header-style = "purple";
          merge-conflict-theirs-diff-header-decoration-style = "ul ol";
        };
        interactive = { keep-plus-minus-markers = false; };
      };
    };
  };
}
