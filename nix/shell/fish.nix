{ pkgs, ... }:

{

  home.packages = [
    pkgs.grc
  ];

  programs = {
    fish = {
      enable = true;
      plugins = [
        { name = "z"; src = pkgs.fishPlugins.z.src; }
        { name = "grc"; src = pkgs.fishPlugins.grc.src; }
        { name = "plugin-git"; src = pkgs.fishPlugins.plugin-git; }
        { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish; }
        { name = "async-prompt"; src = pkgs.fishPlugins.async-prompt; }
      ];
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';
      shellAbbrs = {
        neovim = "nvim --listen /tmp/neovim_server.pipe";
        astronvim = "env NVIM_APPNAME=astronvim nvim";
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
