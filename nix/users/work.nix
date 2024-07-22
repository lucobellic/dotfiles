{ ... }:

# ln -s ~/.config/home-manager/nix/users/work.nix ~/.config/home-manager/home.nix
rec {
  home.username = "lhussonn";
  home.homeDirectory = "/home/" + home.username;
  programs.git.userName = "Ludovic Hussonnois";
  programs.git.userEmail = "ludovic.hussonnois@easymile.com";

  imports = [
    ../common.nix
  ];
}
