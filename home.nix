{ ... }:

# ln -s ~/.config/home-manager/nix/users/work.nix ~/.config/home-manager/home.nix
rec {
  home.username = "lhussonn";
  home.homeDirectory = "/home/" + home.username;
  programs.git.settings.user = {
    name = "Ludovic Hussonnois";
    email = "ludovic.hussonnois@easymile.com";
  };

  imports = [ ./nix/common.nix ];
}
