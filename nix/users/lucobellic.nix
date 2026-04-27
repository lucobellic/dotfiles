{ ... }:

rec {
  home.username = "luco";
  home.homeDirectory = "/home/" + home.username;
  programs.git.settings.user = {
    name = "Luco Bellic";
    email = "luco.bellic@protonmail.com";
  };

  imports = [ ../common.nix ];
}
