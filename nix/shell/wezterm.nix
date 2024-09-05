{ config, ... }:

{

  xdg.configFile.wezterm.source = config.lib.file.mkOutOfStoreSymlink ../../.config/wezterm;

}
