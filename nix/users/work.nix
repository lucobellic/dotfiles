{ ... }:

rec {
  home.username = "lhussonn";
  home.homeDirectory = "/home/" + home.username;
  programs.git.settings.user = {
    name = "Ludovic Hussonnois";
    email = "ludovic.hussonnois@easymile.com";
  };

  imports = [ ../common.nix ];
}
