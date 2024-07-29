{ ... }:

{
  # Does not work (https://github.com/NixOS/nixpkgs/issues/80936)
  # programs.kitty.enable = true;

  xdg.configFile.kitty.source = ../.config/kitty;

}
