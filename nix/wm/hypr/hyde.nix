{ config, pkgs, ... }:

{
  nixGL.packages = import <nixgl> { inherit pkgs; };
  nixGL.defaultWrapper = "mesa";
  nixGL.installScripts = [ "mesa" ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.hyprland;
    settings = { };
    extraConfig = ''source = ~/.config/home-manager/config/hypr/hyprland.conf'';
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      (config.lib.nixGL.wrap xdg-desktop-portal-gnome)
      (config.lib.nixGL.wrap xdg-desktop-portal-gtk)
    ];
  };

  home.packages = with pkgs; [
    xwayland

    # Hardware acceleration on NVIDIA and Wayland
    nvidia-vaapi-driver

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
    (config.lib.nixGL.wrap hyprlock)
    # (config.lib.nixGL.wrap hyprland)
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
  ];


  xdg.configFile."hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/hypr/hyprlock.conf;
  xdg.configFile.qt5ct.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/qt5ct;
  xdg.configFile.qt6ct.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/qt6ct;

  home.file.".local/share/bin" = {
    recursive = true;
    source = ~/.config/home-manager/config/hypr/tools/bin;
  };

}
