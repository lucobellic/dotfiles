{ config, pkgs, ... }:

{
  home.packages = [ pkgs.wezterm ];
  xdg.configFile.wezterm.source = config.lib.file.mkOutOfStoreSymlink ../../config/wezterm;

}
