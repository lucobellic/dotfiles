{ pkgs, ... }:

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
        . $HOME/.config/wezterm/shell-integration/wezterm.sh
        . $HOME/.config/wezterm/shell-integration/shell-inegration.zsh
        export PATH="$PATH:$HOME/.cargo/bin:$HOME/.nix-profile/bin"
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export LIBVA_DRIVER_NAME=nvidia
        export XDG_SESSION_TYPE=wayland
        export GBM_BACKEND=nvidia-drm
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __GL_GSYNC_ALLOWED=1
        export __GL_VRR_ALLOWED=1
        export WLR_NO_HARDWARE_CURSORS=1
        export WLR_DRM_NO_ATOMIC=1
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
        "--color gutter:-1,info:12,border:#1a2632"
        "--color prompt:2,bg+:#111d2c,hl+:#e7b774,hl:#e7b774,pointer:7"
      ];
    };

    z-lua = {
      enable = true;
    };
  };

}
