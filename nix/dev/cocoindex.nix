{ pkgs, lib, ... }: {

  # NOTE: this is super slow to install use `uv` and venv instead
  # home.activation.installCocoindex =
  #   lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #     # Install cocoindex with embeddings using pip with --break-system-packages
  #     ${pkgs.python3.withPackages (ps: with ps; [ pip ])}/bin/python3 -m pip install --break-system-packages --prefix=$HOME/.local 'cocoindex[embeddings]'
  #   '';
  #
  home.activation.installUvTools =
    lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
      ${pkgs.uv}/bin/uv tool install mcp-server-qdrant
    '';

  # Set database URL environment variable
  home.sessionVariables = {
    COCOINDEX_DATABASE_URL =
      "postgresql://cocoindex:cocoindex@localhost:5432/cocoindex";
  };

  # Setup PostgreSQL via docker-compose following docker.nix convention
  systemd.user.services.cocoindex-postgres-compose = {
    Unit = {
      Description = "CocoIndex PostgreSQL Docker Compose";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart =
        "${pkgs.docker-compose}/bin/docker-compose -f %h/.config/home-manager/config/cocoindex/docker-compose.yml up";
      WorkingDirectory = "%h/.config/home-manager/config/cocoindex";
      Restart = "always";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };
}
