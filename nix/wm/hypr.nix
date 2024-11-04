{ config, pkgs, ... }:

{

  home.packages = [
    pkgs.hyprpicker # color picker
    pkgs.hyprlock
    pkgs.libnotify # for notifications
    pkgs.mako
    pkgs.networkmanager # network manager
    pkgs.grimblast # screenshot tool
    pkgs.swaylock-effects # lock screen
    pkgs.swww
    pkgs.rofi-wayland
    pkgs.xdg-desktop-portal-hyprland # xdg desktop portal for hyprland
    pkgs.imagemagick
  ];

  xdg.configFile.hypr.source = config.lib.file.mkOutOfStoreSymlink ../../.config/hypr;
  home.file.".local/share/bin" = {
    recursive = true;
    source = ../../.config/hypr/tools/bin;
  };

}
