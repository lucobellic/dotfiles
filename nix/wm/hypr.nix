{ config, pkgs, ... }:

{

  home.packages = with pkgs; [
    mesa
    libglvnd
    # If using NVIDIA
    # nvidia-vaapi-driver
    # Or for AMD/Intel
    libva
    # pkgs.ark
    blueman
    bluez
    brightnessctl
    # cava
    cliphist
    dunst
    fastfetch
    kdePackages.ffmpegthumbs
    gamemode
    grim
    grimblast # screenshot tool
    # swaylock # install from package manager
    hyprlock # build from source
    hyprpaper
    hyprpicker # color picker
    hyprutils
    imagemagick
    kdePackages.kde-cli-tools
    libnotify # for notifications
    mako
    mangohud
    networkmanager # network manager
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
    xdg-desktop-portal-hyprland # xdg desktop portal for hyprland
  ];


  # imports = [
  #   ./hyprpanel.nix
  # ];

  # hardware.graphics.enable = true;

  xdg.configFile.hypr.source = config.lib.file.mkOutOfStoreSymlink ../../config/hypr;

  xdg.configFile.cava.source = config.lib.file.mkOutOfStoreSymlink ../../config/cava;
  xdg.configFile.dunst.source = config.lib.file.mkOutOfStoreSymlink ../../config/dunst;
  xdg.configFile.qt5ct.source = config.lib.file.mkOutOfStoreSymlink ../../config/qt5ct;
  xdg.configFile.qt6ct.source = config.lib.file.mkOutOfStoreSymlink ../../config/qt6ct;
  xdg.configFile.rofi.source = config.lib.file.mkOutOfStoreSymlink ../../config/rofi;
  xdg.configFile.wlogout.source = config.lib.file.mkOutOfStoreSymlink ../../config/wlogout;
  xdg.configFile.waybar.source = config.lib.file.mkOutOfStoreSymlink ../../config/waybar;
  xdg.configFile.swaylock.source = config.lib.file.mkOutOfStoreSymlink ../../config/swaylock;

  home.file.".local/share/bin" = {
    recursive = true;
    source = ../../config/hypr/tools/bin;
  };

}
