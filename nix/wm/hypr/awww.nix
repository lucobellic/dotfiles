{ pkgs, awww, ... }:
{
  home.packages = [ awww.packages.${pkgs.stdenv.hostPlatform.system}.awww ];
}
