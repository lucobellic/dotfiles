{ pkgs, ... }:
let
  awwwFlake = builtins.getFlake "git+https://codeberg.org/LGFae/awww";
in
{
  home.packages = [ awwwFlake.packages.${pkgs.stdenv.hostPlatform.system}.awww ];
}
