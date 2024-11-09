{ config, pkgs, ... }:

{

  home.packages = [
    pkgs.hyprpicker # color picker
    pkgs.libnotify # for notifications
    pkgs.mako
    pkgs.networkmanager # network manager
    pkgs.grimblast # screenshot tool
    pkgs.swww
    pkgs.rofi-wayland
    pkgs.xdg-desktop-portal-hyprland # xdg desktop portal for hyprland
    pkgs.imagemagick
  ];

  xdg.configFile.hypr.source = config.lib.file.mkOutOfStoreSymlink ../../.config/hypr;

  xdg.configFile.cava.source = config.lib.file.mkOutOfStoreSymlink ../../.config/cava;
  xdg.configFile.dunst.source = config.lib.file.mkOutOfStoreSymlink ../../.config/dunst;
  xdg.configFile.qt5ct.source = config.lib.file.mkOutOfStoreSymlink ../../.config/qt5ct;
  xdg.configFile.qt6ct.source = config.lib.file.mkOutOfStoreSymlink ../../.config/qt6ct;
  xdg.configFile.rofi.source = config.lib.file.mkOutOfStoreSymlink ../../.config/rofi;
  xdg.configFile.wlogout.source = config.lib.file.mkOutOfStoreSymlink ../../.config/wlogout;

  home.file.".local/share/bin" = {
    recursive = true;
    source = ../../.config/hypr/tools/bin;
  };

}
