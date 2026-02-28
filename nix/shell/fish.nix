{ pkgs, ... }:

let
  opencodePort = "4096";
  opencodeUrl = "http://localhost:${opencodePort}";
in
{

  home.packages = [
    pkgs.fish
    pkgs.grc
    pkgs.pyenv
  ];

  home.file.".config/fish/themes/ayu-gloom.theme".source = ../../config/fish/themes/ayu-gloom.theme;
  home.file.".config/fish/conf.d/theme.fish".source = ../../config/fish/conf.d/theme.fish;

  programs = {
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    fzf = {
      enable = true;
      enableFishIntegration = false;
      defaultCommand = "rg --files --hidden --follow --no-ignore-vcs";
      defaultOptions = [
        "--layout=reverse"
        "--info=inline"
        "--color info:12,border:#1a2632"
        "--color prompt:2,bg+:#111d2c,hl+:#e7b774,hl:#e7b774,pointer:7"
      ];
    };

    fish = {
      enable = true;
      plugins = [
        {
          name = "grc";
          src = pkgs.fishPlugins.grc.src;
        }
        {
          name = "plugin-git";
          src = pkgs.fishPlugins.plugin-git.src;
        }
        {
          name = "bass";
          src = pkgs.fishPlugins.bass.src;
        }
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
      ];
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
        set -x PATH $HOME/.local/bin $PATH
        set -x PATH $HOME/.pyenv/bin $PATH
        set -x PATH $HOME/.cargo/bin $PATH
        starship init fish | source # Initialize starship
        function fish_prompt
          starship prompt | awk 'NF'
        end
        zoxide init fish | source # Initialize zoxide
        status --is-interactive; and source (pyenv init --path | psub)
        status --is-interactive; and source (pyenv init - | psub)

        # Auto-add SSH keys if agent is running and keys exist
        if test -n "$SSH_AUTH_SOCK"
          for key in ~/.ssh/github_personal ~/.ssh/gitlab ~/.ssh/gitlab_perso ~/.ssh/read ~/.ssh/testbench
            if test -f "$key"
              ssh-add -l | grep -q (ssh-keygen -lf "$key" | awk '{print $2}') || ssh-add "$key" 2>/dev/null
            end
          end
        end
      '';
      shellAbbrs = {
        neovim = "nvim --listen /tmp/neovim_server.pipe";
        astronvim = "NVIM_APPNAME=astronvim nvim";
        nvchad = "NVIM_APPNAME=nvchad nvim";
        caelestia-shell = "quickshell -c caelestia";
        oc = "opencode attach ${opencodeUrl}";
        start-docker = ''
          cd ~/Development/work/rapidash
          if test (docker container inspect --format '{{.State.Running}}' rapidash) = "true"
            ./reach docker exec --container rapidash zsh
          else
            ./reach docker run --name rapidash --docker-build=allow zsh
          end
          cd -
        '';
      };
    };
  };
}
