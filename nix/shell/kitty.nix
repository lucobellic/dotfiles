{ config, pkgs, ... }:

{
  home.packages = [ (config.lib.nixGL.wrapOffload pkgs.kitty) ];
  xdg.configFile.kitty.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/kitty;
}
