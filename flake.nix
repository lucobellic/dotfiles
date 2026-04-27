{
  description = "lhussonn home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww = {
      url = "git+https://codeberg.org/LGFae/awww?ref=refs/heads/main&rev=2c86d41d07471f518e24f5cd1f586e4d2a32d12c";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    silent-sddm = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      sops-nix,
      awww,
      silent-sddm,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      mkHome =
        userModule:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            userModule
            sops-nix.homeManagerModules.sops
          ];
          extraSpecialArgs = {
            inherit
              awww
              silent-sddm
              ;
          };
        };
    in
    {
      homeConfigurations = {
        lhussonn = mkHome ./nix/users/work.nix;
        luco = mkHome ./nix/users/lucobellic.nix;
        rosuser = mkHome ./nix/users/rosuser.nix;
      };
    };
}
