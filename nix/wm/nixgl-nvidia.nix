{ config, pkgs, ... }:

{
  # Configure nixGL using the built-in home-manager module with the default nixGL import
  nixGL = {
    packages = import <nixgl> {
      inherit pkgs;
      # Specify NVIDIA version to avoid auto-detection issues
      nvidiaVersion = "575.64.03";
      nvidiaHash = "sha256-S7eqhgBLLtKZx9QwoGIsXJAyfOOspPbppTHUxB06DKA=";
    };
    defaultWrapper = "mesa";
    offloadWrapper = "nvidia";
    installScripts = [ "mesa" "mesaPrime" "nvidia" "nvidiaPrime" ];
  };

}
