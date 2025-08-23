{ config, pkgs, ... }:

{
  imports = [
    ../nixgl-nvidia.nix
    ../quickshell.nix
    ./fonts.nix
    ./hyde.nix
    ./caelestia.nix
    # ./end4.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      wayland-bongocat = final.callPackage ../bongocat.nix { };
    })
  ];
  home.packages = [ pkgs.wayland-bongocat ];
  xdg.configFile.bongocat.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/bongocat;

  xdg.configFile.dunst.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/dunst;
  xdg.configFile.rofi.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/rofi;
  xdg.configFile.wlogout.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/wlogout;
  xdg.configFile.waybar.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/waybar;
  xdg.configFile.swaylock.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/swaylock;

}
