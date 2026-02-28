{ pkgs, ... }:

{

  home.packages = [
    pkgs.ripgrep
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
      ];
      shellAliases = {
        neovim = "nvim --listen /tmp/neovim_server.pipe";
        astronvim = "NVIM_APPNAME=astronvim nvim";
        start-docker = ''
          cd ~/Development/work/rapidash
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

        # Fix completion issues with magic_equal_subst
        # Disable problematic completers and use safer options
        zstyle ':completion:*' completer _complete _ignored
        zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|[._-]=* r:|=*'

        # Ensure completion works properly after = sign
        compdef '_files -/' '*:*='

        bindkey -M menuselect '\r' .accept-line
        bindkey "^[[H" beginning-of-line
        bindkey "^[[F" end-of-line
        bindkey "^H" backward-kill-word
        . $HOME/.config/wezterm/shell-integration/wezterm.sh
        . $HOME/.config/wezterm/shell-integration/shell-inegration.zsh
        export PATH="$PATH:$HOME/.cargo/bin:$HOME/.nix-profile/bin"
        export XCURSOR_SIZE=12
      '';
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
        "--info=inline"
        "--color info:12,border:#1a2632"
        "--color prompt:2,bg+:#111d2c,hl+:#e7b774,hl:#e7b774,pointer:7"
      ];
    };

    z-lua = {
      enable = true;
    };
  };

}
