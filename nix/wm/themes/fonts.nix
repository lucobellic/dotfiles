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
in
{
  home.packages = [
    gabarito
    rubik
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts._0xproto
    pkgs.papirus-icon-theme
  ];

  fonts.fontconfig.enable = true;
}
