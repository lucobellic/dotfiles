{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    (config.lib.nixGL.wrap baobab)

    brightnessctl
    cliphist
    fastfetch
    kdePackages.ffmpegthumbs
    # swaylock # install from package manager
    (config.lib.nixGL.wrap hyprlock)
    hyprpaper
    hyprpicker # color picker
    hyprutils
    hyprcursor
    imagemagick
    libnotify # for notifications
    # mangohud
    # networkmanager # network manager
    dunst
    # nwg-look
    # pamixer
    # parallel
    # pavucontrol
    rofi
    # slurp
    # swappy
    # swww
    # udiskie
    waybar
    wl-clipboard
    wl-gammarelay-rs
    wlogout
    wlr-randr
    wofi
  ];


  xdg.configFile.qt5ct.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/qt5ct;
  xdg.configFile.qt6ct.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/qt6ct;

  home.file.".local/share/bin" = {
    recursive = true;
    source = ~/.config/home-manager/config/hypr/tools/bin;
  };

}
