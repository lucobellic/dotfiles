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
  home.packages = with pkgs; [
    (config.lib.nixGL.wrap quickshell)

    qt6.qt5compat
    qt6.full
    qt6ct
  ];


  home.sessionVariables = {
    LD_LIBRARY_PATH = "${pkgs.qt6.full}/lib:${pkgs.qt6.qt5compat}/lib:$LD_LIBRARY_PATH";
    QT_PLUGIN_PATH = "${pkgs.qt6.full}/lib/qt-6/plugins:${pkgs.qt6.qt5compat}/lib/qt-6/plugins:${pkgs.qt6ct}/lib/qt-6/plugins";
    QML2_IMPORT_PATH = "${pkgs.qt6.full}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml";
    QT_QPA_PLATFORMTHEME = "gtk3";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };

  home.sessionPath = [
    "${pkgs.qt6.full}/lib"
    "${pkgs.qt6.qt5compat}/lib"
    "${pkgs.qt6ct}/bin"
  ];

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

}
