{ pkgs, ... }:

{

  home.packages = [ pkgs.fish pkgs.grc pkgs.pyenv ];

  programs = {
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    fzf = {
      enable = true;
      enableFishIntegration = false;
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
      shellInit = ''
        # Colorscheme: ayu Dark
        set -U fish_color_normal BFBDB6
        set -U fish_color_command 39BAE6
        set -U fish_color_quote AAD94C
        set -U fish_color_redirection FFEE99
        set -U fish_color_end F29668
        set -U fish_color_error F26D78
        set -U fish_color_param D2A6FF
        set -U fish_color_comment 626A73
        set -U fish_color_match F07178
        set -U fish_color_selection --background=152538
        set -U fish_color_search_match --background=2D4965
        set -U fish_color_history_current --bold
        set -U fish_color_operator FF8F40
        set -U fish_color_escape 95E6CB
        set -U fish_color_cwd 59C2FF
        set -U fish_color_cwd_root red
        set -U fish_color_valid_path D2A6FF
        set -U fish_color_autosuggestion 4D5566
        set -U fish_color_user brgreen
        set -U fish_color_host normal
        set -U fish_color_cancel --reverse
        set -U fish_pager_color_prefix normal --bold
        set -U fish_pager_color_progress brwhite --background=cyan
        set -U fish_pager_color_completion normal
        set -U fish_pager_color_description 95E6CB
        set -U fish_pager_color_selected_background --background=152538
        set -U fish_color_option
        set -U fish_pager_color_selected_description
        set -U fish_pager_color_background
        set -U fish_pager_color_secondary_completion
        set -U fish_color_host_remote
        set -U fish_pager_color_secondary_background
        set -U fish_color_keyword
        set -U fish_pager_color_selected_prefix
        set -U fish_pager_color_selected_completion
        set -U fish_pager_color_secondary_description
        set -U fish_pager_color_secondary_prefix
      '';
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
        starship init fish | source # Initialize starship
        zoxide init fish | source # Initialize zoxide
        set -x PATH $HOME/.local/bin $PATH
        set -x PATH $HOME/.pyenv/bin $PATH
        status --is-interactive; and source (pyenv init --path | psub)
        status --is-interactive; and source (pyenv init - | psub)
      '';
      shellAbbrs = {
        neovim = "nvim --listen /tmp/neovim_server.pipe";
        astronvim = "NVIM_APPNAME=astronvim nvim";
        start-docker = ''
          cd ~/Development/rapidash
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
