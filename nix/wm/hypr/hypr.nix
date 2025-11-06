{ config, pkgs, ... }:

let
  mkConfigSymlink = path:
    config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/${path};
in {
  imports = [
    ./ags.nix
    ./hyprlock.nix
    # ./xdg-desktop-portal.nix
  ];

  home.packages = with pkgs; [
    # Install from package manager:
    # cliphist
    # swaylock
    # pavucontrol
    # hyprland
    # xdg-desktop-portal-hyprland
    # xdg-desktop-portal-gtk

    (config.lib.nixGL.wrap baobab)
    brightnessctl
    dunst
    fastfetch
    hyprcursor

    (config.lib.nixGL.wrap eww)
    hyprsysteminfo

    # polkit authentication daemon required for GUI applications to request elevated privileges
    hyprpolkitagent

    # wallpaper
    hyprpaper
    matugen

    hyprpicker # color picker
    hyprutils
    hyprshade
    # hyprsunset hyprland v0.45
    (config.lib.nixGL.wrap hyprpanel)

    swappy
    grim
    slurp
    grimblast
    imagemagick
    kdePackages.ffmpegthumbs
    libnotify # for notifications
    parallel
    udiskie
    wl-clipboard
    wl-gammarelay-rs
    wlr-randr

    # Launchers
    (config.lib.nixGL.wrap onagre)
    (config.lib.nixGL.wrapOffload walker)
    # elephant
    rofi
    wofi
  ];

  xdg.configFile.dunst.source = mkConfigSymlink "dunst";
  xdg.configFile.eww.source = mkConfigSymlink "eww";
  xdg.configFile.hypr.source = mkConfigSymlink "hypr";
  xdg.configFile.hyprpanel.source = mkConfigSymlink "hyprpanel";
  xdg.configFile.onagre.source = mkConfigSymlink "onagre";
  xdg.configFile.rofi.source = mkConfigSymlink "rofi";
  xdg.configFile.swaylock.source = mkConfigSymlink "swaylock";
  xdg.configFile.walker.source = mkConfigSymlink "walker";
  xdg.configFile.wlogout.source = mkConfigSymlink "wlogout";

  home.file.".local/share/bin" = {
    recursive = true;
    source = ~/.config/home-manager/config/hypr/tools/bin;
  };

  xdg.configFile."xdg-desktop-portal/hyprland-portals.conf".source =
    config.lib.file.mkOutOfStoreSymlink
    ~/.config/home-manager/config/xdg-desktop-portal/hyprland-portals.conf;

  # Desktop Entries

  xdg.dataFile."applications/logout.desktop".source =
    mkConfigSymlink "desktop-entry/logout.desktop";

  xdg.dataFile."applications/poweroff.desktop".source =
    mkConfigSymlink "desktop-entry/poweroff.desktop";

}
