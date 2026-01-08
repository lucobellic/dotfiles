{ config, pkgs, ... }:
let
  mkConfigSymlink = path: config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/${path};
in
{
  imports = [
    ./ags.nix
    ./awww.nix
  ];

  programs = {
    # TODO: to be tested and constumized
    # mcp = {enable = true; };bled =}
    # vicinae = { enable = true; };
    bluetuith = {
      enable = true;
    };
  };

  home.packages = with pkgs; [
    # Install from package manager:
    # cliphist
    # swaylock
    # pavucontrol
    # hyprland
    # xdg-desktop-portal-hyprland
    # xdg-desktop-portal-gtk

    (config.lib.nixGL.wrap baobab)
    dunst
    fastfetch
    hyprcursor

    (config.lib.nixGL.wrap eww)
    hyprsysteminfo

    # polkit authentication daemon required for GUI applications to request elevated privileges
    hyprpolkitagent

    # wallpaper
    matugen
    hyprland-workspaces
    hyprpicker # color picker
    hyprutils
    hyprshade
    hyprsunset
    hypridle # idle daemon for screen lock and power management
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
    wf-recorder # screen recorder
    wl-clipboard # clipboard manager
    wlr-randr

    # Launchers
    rofi
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
    config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/xdg-desktop-portal/hyprland-portals.conf;

  # Desktop Entries

  xdg.dataFile."applications/logout.desktop".source = mkConfigSymlink "desktop-entry/logout.desktop";

  xdg.dataFile."applications/poweroff.desktop".source =
    mkConfigSymlink "desktop-entry/poweroff.desktop";

}
