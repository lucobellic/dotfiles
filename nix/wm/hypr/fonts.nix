{ pkgs, ... }:

let
  gabarito = pkgs.stdenv.mkDerivation {
    pname = "gabarito";
    version = "unstable";

    src = builtins.fetchGit {
      url = "https://github.com/naipefoundry/gabarito.git";
      ref = "main";
    };

    installPhase = ''
      mkdir -p $out/share/fonts/TTF
      find . -name "*.ttf" -exec cp {} $out/share/fonts/TTF \;
    '';
  };
  rubik = pkgs.stdenv.mkDerivation {
    pname = "rubik";
    version = "unstable";

    src = builtins.fetchGit {
      url = "https://github.com/googlefonts/rubik.git";
      ref = "main";
    };

    installPhase = ''
      mkdir -p $out/share/fonts/TTF
      find . -name "*.ttf" -exec cp {} $out/share/fonts/TTF \;
    '';
  };

  oneui4-cursors = pkgs.stdenv.mkDerivation {
    pname = "oneui4-cursors";
    version = "unstable";

    src = builtins.fetchGit {
      url = "https://github.com/end-4/OneUI4-Icons.git";
      ref = "main";
    };

    installPhase = ''
      mkdir -p $out/share/icons
      echo $out/share/icons

      # Remove mimetypes with missing symlinks
      rm OneUI/scalable/mimetypes/gnome-mime-application-x-vnc.svg
      rm OneUI/scalable/mimetypes/application-x-vnc.svg
      rm OneUI/scalable/mimetypes/gnome-mime-application-x-remote-connection.svg
      rm OneUI/scalable/mimetypes/gnome-mime-application-x-bittorrent.svg
      rm OneUI/scalable/mimetypes/document-photoshop.svg
      rm OneUI/scalable/mimetypes/document-illustrator.svg
      rm OneUI/scalable/mimetypes/gnome-mime-application-x-scribus.svg
      rm OneUI/scalable/mimetypes/gnome-mime-application-vnd.scribus.svg

      cp -r OneUI $out/share/icons/
      cp -r OneUI-dark $out/share/icons/
      cp -r OneUI-light $out/share/icons/
    '';
  };

  bibata-cursors = pkgs.stdenv.mkDerivation {
    pname = "bibata-cursors";
    version = "unstable";

    src = builtins.fetchTarball {
      url = "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic-Right.tar.xz";
    };

    installPhase = ''
      mkdir -p $out/share/icons
      cp -r * $out/share/icons/
    '';
  };
in
{
  home.packages = [
    gabarito
    rubik
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts._0xproto
    pkgs.papirus-icon-theme
    oneui4-cursors
    bibata-cursors
  ];

  fonts.fontconfig.enable = true;
}
