{ ... }:

# ln -s ~/.config/home-manager/nix/users/lucobellic.nix ~/.config/home-manager/home.nix
rec {
  home.username = "luco";
  home.homeDirectory = "/home/" + home.username;
  programs.git.settings.user = {
    name = "Luco Bellic";
    email = "luco.bellic@protonmail.com";
  };

  imports = [ ./nix/common.nix ];
}
