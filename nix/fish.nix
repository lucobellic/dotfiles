{ pkgs, ... }:

{

  home.packages = [
    pkgs.ripgrep
    pkgs.yarn
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
    };
  };

  imports = [
    ./starship.nix
  ];

}
