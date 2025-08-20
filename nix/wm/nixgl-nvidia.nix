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
    defaultWrapper = "nvidia";
    installScripts = [ "nvidia" ];
  };

  # Set environment variables for NVIDIA
  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
  };
}
