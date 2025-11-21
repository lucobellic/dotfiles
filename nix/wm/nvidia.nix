{ ... }: {
  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
  };

  targets.genericLinux = {
    nixGL.prime.installScript = "nvidia";
    gpu.nvidia = {
      enable = true;
      version = "580.95.05";
      sha256 = "sha256-hJ7w746EK5gGss3p8RwTA9VPGpp2lGfk5dlhsv4Rgqc=";
    };
  };
}
