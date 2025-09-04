{ pkgs, ... }:

{
  # Configure nixGL using the built-in home-manager module with the default nixGL import
  nixGL = {
    packages = import <nixgl> {
      inherit pkgs;
      # Specify NVIDIA version to avoid auto-detection issues
      nvidiaVersion = "570.169";
      nvidiaHash = "sha256-XzKoR3lcxcP5gPeRiausBw2RSB1702AcAsKCndOHN2U=";
    };
    defaultWrapper = "mesa";
    offloadWrapper = "nvidiaPrime";
    installScripts = [ "mesa" "mesaPrime" "nvidia" "nvidiaPrime" ];
  };

}
