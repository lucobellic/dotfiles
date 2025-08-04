{ ... }:

# ln -s ~/.config/home-manager/nix/users/lucobellic.nix ~/.config/home-manager/home.nix
rec {
  home.username = "luco";
  home.homeDirectory = "/home/" + home.username;
  programs.git.userName = "Luco Bellic";
  programs.git.userEmail = "luco.bellic@protonmail.com";

  imports = [
    ./nix/common.nix
  ];
}
