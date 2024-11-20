{ config, pkgs, ... }:

{

  home.packages = [
    pkgs.ark
    pkgs.blueman
    pkgs.bluez
    pkgs.brightnessctl
    pkgs.cava
    pkgs.cliphist
    pkgs.dolphin
    pkgs.dunst
    pkgs.fastfetch
    pkgs.ffmpegthumbs
    pkgs.gamemode
    pkgs.grim
    pkgs.grimblast # screenshot tool
    # pkgs.hyprlock # build from source
    pkgs.hyprpicker # color picker
    pkgs.hyprutils
    pkgs.imagemagick
    pkgs.kde-cli-tools
    pkgs.libnotify # for notifications
    pkgs.mako
    pkgs.mangohud
    pkgs.networkmanager # network manager
    pkgs.nwg-look
    pkgs.pamixer
    pkgs.parallel
    pkgs.pavucontrol
    pkgs.rofi-wayland
    pkgs.slurp
    pkgs.swappy
    pkgs.swww
    pkgs.udiskie
    pkgs.waybar
    pkgs.wireplumber
    pkgs.wl-clipboard
    pkgs.wlogout
    pkgs.wlr-randr
    pkgs.wofi
    pkgs.xdg-desktop-portal-hyprland # xdg desktop portal for hyprland
  ];

  xdg.configFile.hypr.source = config.lib.file.mkOutOfStoreSymlink ../../config/hypr;

  xdg.configFile.cava.source = config.lib.file.mkOutOfStoreSymlink ../../config/cava;
  xdg.configFile.dunst.source = config.lib.file.mkOutOfStoreSymlink ../../config/dunst;
  xdg.configFile.qt5ct.source = config.lib.file.mkOutOfStoreSymlink ../../config/qt5ct;
  xdg.configFile.qt6ct.source = config.lib.file.mkOutOfStoreSymlink ../../config/qt6ct;
  xdg.configFile.rofi.source = config.lib.file.mkOutOfStoreSymlink ../../config/rofi;
  xdg.configFile.wlogout.source = config.lib.file.mkOutOfStoreSymlink ../../config/wlogout;
  xdg.configFile.waybar.source = config.lib.file.mkOutOfStoreSymlink ../../config/waybar;

  home.file.".local/share/bin" = {
    recursive = true;
    source = ../../config/hypr/tools/bin;
  };

}
