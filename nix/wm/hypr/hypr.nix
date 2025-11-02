{ config, pkgs, ... }:

{
  # hyprland
  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   package = config.lib.nixGL.wrap pkgs.hyprland;
  #   settings = { };
  #   extraConfig = ''source = ~/.config/home-manager/config/hypr/hyprland.conf'';
  # };

  # xdg.portal = {
  #   enable = true;
  #   extraPortals = with pkgs; [
  #     (config.lib.nixGL.wrap xdg-desktop-portal-gnome)
  #     (config.lib.nixGL.wrap xdg-desktop-portal-gtk)
  #   ];
  # };
  #
  # home.packages = with pkgs; [
  #   xwayland
  #   nvidia-vaapi-driver
  # ];

  # xdg.configFile."hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/hypr/hyprlock.conf;

  imports = [
    # ../quickshell.nix
    ./bongocat.nix
    ./ags.nix
    # ./caelestia.nix
    # ./end4.nix
  ];

  programs.hyprlock = {
    enable = false;
    package = (config.lib.nixGL.wrap pkgs.hyprlock);
  };

  home.packages = with pkgs; [
    # Install from package manager:
    # cliphist
    # swaylock
    # pavucontrol

    (config.lib.nixGL.wrap baobab)
    # (config.lib.nixGL.wrap hyprlock)
    brightnessctl
    dunst
    fastfetch
    hyprcursor

    (config.lib.nixGL.wrap eww)

    # wallpaper
    hyprpaper
    matugen

    hyprpicker # color picker
    hyprutils
    hyprshade
    # hyprsunset hyprland v0.45
    (config.lib.nixGL.wrap hyprpanel)

    swappy
    grimblast
    imagemagick
    kdePackages.ffmpegthumbs
    libnotify # for notifications
    parallel
    udiskie
    wl-clipboard
    wl-gammarelay-rs
    wlogout
    wlr-randr

    # Launchers
    rofi
    (config.lib.nixGL.wrapOffload walker)
    # elephant
    wofi
  ];

  xdg.configFile.dunst.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/dunst;
  xdg.configFile.eww.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/eww;
  xdg.configFile.hypr.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/hypr;
  xdg.configFile.rofi.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/rofi;
  xdg.configFile.swaylock.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/swaylock;
  xdg.configFile.walker.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/walker;
  xdg.configFile.wlogout.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/wlogout;

  home.file.".local/share/bin" = {
    recursive = true;
    source = ~/.config/home-manager/config/hypr/tools/bin;
  };

  # Desktop Entries

  xdg.dataFile."applications/logout.desktop".source =
    config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/desktop-entry/logout.desktop;

  xdg.dataFile."applications/poweroff.desktop".source =
    config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/desktop-entry/poweroff.desktop;

}
