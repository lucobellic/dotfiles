{ config, ... }:

{
  # wayland.windowManager.hyprland.enable = true;

  imports = [
    ../nixgl-nvidia.nix
    ../quickshell.nix
    ./fonts.nix
    ./hyde.nix
    ./caelestia.nix
    # ./end4.nix
  ];

  xdg.configFile.cava.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/cava;
  xdg.configFile.dunst.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/dunst;
  xdg.configFile.rofi.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/rofi;
  xdg.configFile.wlogout.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/wlogout;
  xdg.configFile.waybar.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/waybar;
  xdg.configFile.swaylock.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/swaylock;

}
