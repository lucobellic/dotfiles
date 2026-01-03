{ pkgs, config, ... }:

let
  sipConfigDir = "${config.home.homeDirectory}/.config/home-manager/config/sip-startpage";
  sipPort = "7426";
in
{
  # Sip-StartPage docker-compose service
  systemd.user.services.sip-startpage = {
    Unit = {
      Description = "Sip-StartPage - A modern startpage dashboard";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      WorkingDirectory = sipConfigDir;
      Environment = "PATH=${pkgs.docker}/bin:${pkgs.docker-compose}/bin:/run/current-system/sw/bin:/usr/bin";
      ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.docker-compose}/bin/docker-compose -f ${sipConfigDir}/docker-compose.yml down --remove-orphans 2>/dev/null || true'";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${sipConfigDir}/docker-compose.yml up";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${sipConfigDir}/docker-compose.yml down";
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Override docker-compose port via environment
  home.file."${sipConfigDir}/.env".text = ''
    SIP_PORT=${sipPort}
  '';
}
