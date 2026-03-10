{ pkgs, config, ... }:

{
  home.packages = [ (config.lib.nixGL.wrapOffload pkgs.ghostty) ];
  xdg.configFile.ghostty.source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/config/ghostty";
}
