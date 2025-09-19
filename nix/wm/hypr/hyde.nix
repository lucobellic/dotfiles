{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Install from package manager:
    # cliphist
    # swaylock
    # pavucontrol

    (config.lib.nixGL.wrap baobab)
    (config.lib.nixGL.wrap hyprlock)
    brightnessctl
    dunst
    fastfetch
    hyprcursor

    # wallpaper
    hyprpaper
    swww

    hyprpicker # color picker
    hyprutils
    hyprshade
    swappy
    grimblast
    imagemagick
    kdePackages.ffmpegthumbs
    libnotify # for notifications
    parallel
    rofi
    udiskie
    waybar
    wl-clipboard
    wl-gammarelay-rs
    wlogout
    wlr-randr
    wofi
  ];

  # xdg.configFile.qt5ct.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/qt5ct;
  # xdg.configFile.qt6ct.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/qt6ct;

  home.file.".local/share/bin" = {
    recursive = true;
    source = ~/.config/home-manager/config/hypr/tools/bin;
  };

}
