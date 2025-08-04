{ config, ... }:

{
  # wayland.windowManager.hyprland.enable = true;

  imports = [
    ./hyde/hypr.nix
    # ./end4/hypr.nix
  ];

  xdg.configFile.cava.source = config.lib.file.mkOutOfStoreSymlink ../../../config/cava;
  xdg.configFile.dunst.source = config.lib.file.mkOutOfStoreSymlink ../../../config/dunst;
  xdg.configFile.rofi.source = config.lib.file.mkOutOfStoreSymlink ../../../config/rofi;
  xdg.configFile.wlogout.source = config.lib.file.mkOutOfStoreSymlink ../../../config/wlogout;
  xdg.configFile.waybar.source = config.lib.file.mkOutOfStoreSymlink ../../../config/waybar;
  xdg.configFile.swaylock.source = config.lib.file.mkOutOfStoreSymlink ../../../config/swaylock;

}
