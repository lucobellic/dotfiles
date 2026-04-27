{ config, pkgs, ... }:

{
  xdg.configFile.nix.source = config.lib.file.mkOutOfStoreSymlink ../config/nix;

  # Required for nix.settings to work in standalone home-manager (non-NixOS)
  nix.package = pkgs.nix;
}
