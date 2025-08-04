{ ... }:

# ln -s ~/.config/home-manager/nix/users/rosuser.nix ~/.config/home-manager/home.nix
rec {
  home.username = "rosuser";
  home.homeDirectory = "/home/" + home.username;
  programs.git.userName = "Ludovic Hussonnois";
  programs.git.userEmail = "ludovic.hussonnois@easymile.com";

  imports = [
    ./nix/common.nix
  ];
}
