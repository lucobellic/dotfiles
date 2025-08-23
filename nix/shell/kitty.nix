{ config, pkgs, ... }:

{
  programs.kitty = {
    package = (config.lib.nixGL.wrapOffload pkgs.kitty);
    enable = true;
    extraConfig = builtins.readFile ~/.config/home-manager/config/kitty/kitty.conf;
  };

  # xdg.configFile.kitty.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/kitty;
}
