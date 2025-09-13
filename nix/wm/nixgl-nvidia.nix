{ pkgs, ... }:

{
  # Configure nixGL using the built-in home-manager module with the default nixGL import
  nixGL = {
    packages = import <nixgl> {
      inherit pkgs;
      # Specify NVIDIA version to avoid auto-detection issues
      nvidiaVersion = "580.65.06";
      nvidiaHash = "sha256-BLEIZ69YXnZc+/3POe1fS9ESN1vrqwFy6qGHxqpQJP8=";
    };
    defaultWrapper = "mesa";
    offloadWrapper = "nvidiaPrime";
    installScripts = [ "mesa" "mesaPrime" "nvidia" "nvidiaPrime" ];
  };

}
