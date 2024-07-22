{ pkgs, ... }:

let typewritten_symbol = if builtins.getEnv "INSIDE_DOCKER" != "" then "󰡨" else " "; in
{

  home.packages = [
    pkgs.ripgrep
    pkgs.yarn
  ];

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting = {
        enable = false;
      };
      plugins = [
        {
          name = "fast-syntax-highlighting";
          src = pkgs.fetchFromGitHub {
            owner = "zdharma-continuum";
            repo = "fast-syntax-highlighting";
            rev = "v1.55";
            sha256 = "sha256-DWVFBoICroKaKgByLmDEo4O+xo6eA8YO792g8t8R7kA=";
          };
        }
        {
          name = "typewritten";
          src = pkgs.fetchFromGitHub {
            owner = "reobin";
            repo = "typewritten";
            rev = "v1.5.1";
            sha256 = "sha256-qiC4IbmvpIseSnldt3dhEMsYSILpp7epBTZ53jY18x8=";
          };
        }
      ];
      shellAliases = {
        neovim = "nvim --listen /tmp/neovim_server.pipe";
        astronvim = "NVIM_APPNAME=astronvim nvim";
        start-docker = ''
          cd ~/Development/rapidash
          if [[ "$( docker container inspect --format '{{.State.Running}}' rapidash )" == "true" ]]
          then
              ./reach docker exec --container rapidash zsh
          else
              ./reach docker run --name rapidash --docker-build=allow zsh
          fi
          cd -
        '';
      };
      initExtra = ''
        setopt magic_equal_subst
        bindkey -M menuselect '\r' .accept-line
        bindkey "^[[H" beginning-of-line
        bindkey "^[[F" end-of-line
        bindkey "^H" backward-kill-word
        . $HOME/.dotfiles/wezterm/shell-integration/wezterm.sh
        . $HOME/.dotfiles/wezterm/shell-integration/shell-inegration.zsh
      '';
      sessionVariables = {
        NVIM_SERVER = "/tmp/neovim_server.pipe";
        TYPEWRITTEN_PROMPT_LAYOUT = "half_pure";
        TYPEWRITTEN_RELATIVE_PATH = "git";
        TYPEWRITTEN_SYMBOL = "${typewritten_symbol}";
        ZSH_DISABLE_COMPFIX = true;
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#626A73";
      };
      oh-my-zsh = {
        enable = true;
        extraConfig = ''
          # disable sort when completing `git checkout`
          zstyle ':completion:*:git-checkout:*' sort false
          # set descriptions format to enable group support
          zstyle ':completion:*:descriptions' format '[%d]'
          # preview directory's content with exa when completing cd
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
          # switch group using `,` and `.`
          zstyle ':fzf-tab:*' switch-group ',' '.'
        '';
        plugins = [
          "git"
          "rust"
          "sudo"
        ];
      };
    };


    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "rg --files --hidden --follow --no-ignore-vcs";
      defaultOptions = [
        "--layout=reverse"
        "--color gutter:-1,info:12,border:#1a2632"
        "--color prompt:2,bg+:#111d2c,hl+:#e7b774,hl:#e7b774,pointer:7"
      ];
    };

    z-lua = {
      enable = true;
    };
  };

}
