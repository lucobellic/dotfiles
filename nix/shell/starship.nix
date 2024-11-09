{ config, ... }:

{

  xdg.configFile."starship.toml".source = config.lib.file.mkOutOfStoreSymlink ../../config/starship.toml;

  programs = {
    starship = {
      enable = true;
    };
  };
}
