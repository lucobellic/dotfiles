{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    (config.lib.nixGL.wrap baobab)

    blueman
    bluez
    brightnessctl
    cliphist
    fastfetch
    kdePackages.ffmpegthumbs
    gamemode
    grim
    grimblast # screenshot tool
    # swaylock # install from package manager
    (config.lib.nixGL.wrap hyprlock)

    hyprpaper
    hyprpicker # color picker
    hyprutils
    imagemagick
    kdePackages.kde-cli-tools
    libnotify # for notifications
    mangohud
    networkmanager # network manager
    dunst
    nwg-look
    pamixer
    parallel
    pavucontrol
    rofi-wayland
    slurp
    swappy
    swww
    udiskie
    waybar
    wireplumber
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
