{ config, ... }:

{
  xdg.configFile.nix.source = config.lib.file.mkOutOfStoreSymlink ../config/nix;
}
