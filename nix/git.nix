{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    lazygit
    git
    delta
  ];

  xdg.configFile.lazygit.source = config.lib.file.mkOutOfStoreSymlink ../config/lazygit;
}
