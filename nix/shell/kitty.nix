{ config, ... }:

{
  # Does not work (https://github.com/NixOS/nixpkgs/issues/80936)
  # programs.kitty = {
  #   enable = true;
  #   extraConfig = builtins.readFile ../../config/kitty/kitty.conf;
  # };

  xdg.configFile.kitty.source = config.lib.file.mkOutOfStoreSymlink ../../config/kitty;
}
