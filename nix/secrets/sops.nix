{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    age
    sops
  ];

  sops = {
    age.keyFile = "/home/lhussonn/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    # Required for home-manager on non-NixOS: use XDG_RUNTIME_DIR instead of /run/secrets
    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";

    secrets.anthropic_api_key = { };
    secrets.context7_api_key = { };
  };
}
