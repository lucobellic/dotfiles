{ pkgs, ... }:

{
  # Configure nixGL using the built-in home-manager module with the default nixGL import
  nixGL = {
    packages = import <nixgl> {
      inherit pkgs;
      # Specify NVIDIA version to avoid auto-detection issues
      nvidiaVersion = "580.95.05";
      nvidiaHash = "sha256-hJ7w746EK5gGss3p8RwTA9VPGpp2lGfk5dlhsv4Rgqc=";
    };
    defaultWrapper = "mesa";
    offloadWrapper = "nvidiaPrime";
    installScripts = [ "mesa" "mesaPrime" "nvidia" "nvidiaPrime" ];
  };
}
