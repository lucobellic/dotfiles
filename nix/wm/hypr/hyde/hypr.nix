{ config, pkgs, ... }:

# let
#   quickshell-git = pkgs.stdenv.mkDerivation rec {
#     pname = "quickshell";
#     version = "v0.2.0";
#
#     src = pkgs.fetchFromGitHub {
#       owner = "quickshell-mirror";
#       repo = pname;
#       rev = version;
#       hash = "sha256-vqkSDvh7hWhPvNjMjEDV4KbSCv2jyl2Arh73ZXe274k=";
#     };
#     buildInputs = [
#       pkgs.breakpad
#       pkgs.jemalloc
#       pkgs.libdrm
#       pkgs.pipewire
#       # pkgs.libxcb
#       pkgs.mesa
#       pkgs.qt6.full
#       pkgs.wayland
#       pkgs.wayland-protocols
#       pkgs.wayland-scanner
#     ];
#     nativeBuildInputs = [
#       pkgs.cmake
#       pkgs.ninja
#       pkgs.cli11
#       pkgs.spirv-tools
#       pkgs.pkg-config
#     ];
#     cmakeFlags = [ "-G" "Ninja" "-D" "INSTALL_QML_PREFIX=lib/qt6/qml"];
#   };
# in
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


  xdg.configFile."hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink ../../../../config/hypr/hyprlock.conf;
  xdg.configFile.qt5ct.source = config.lib.file.mkOutOfStoreSymlink ../../../../config/qt5ct;
  xdg.configFile.qt6ct.source = config.lib.file.mkOutOfStoreSymlink ../../../../config/qt6ct;

  home.file.".local/share/bin" = {
    recursive = true;
    source = ../../../../config/hypr/tools/bin;
  };

}
