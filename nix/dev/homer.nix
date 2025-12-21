{ pkgs, config, ... }:

{
  home.packages = with pkgs; [ homer ];

  # Homer dashboard service
  systemd.user.services.homer =
    let
      homerDir = "${config.home.homeDirectory}/.local/share/homer";
      homerConfigDir = "${config.home.homeDirectory}/.config/home-manager/config/homer";
    in
    {
      Unit = {
        Description = "Homer - A dead simple static homepage for your server";
        After = [ "network.target" ];
      };

      Service = {
        Type = "simple";
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'mkdir -p ${homerDir} && ${pkgs.rsync}/bin/rsync -a --delete ${pkgs.homer}/ ${homerDir}/ && chmod -R u+w ${homerDir} && ln -sf ${homerConfigDir}/config.yml ${homerDir}/assets/config.yml && ln -sf ${homerConfigDir}/custom.css ${homerDir}/assets/custom.css'";
        ExecStart = "${pkgs.darkhttpd}/bin/darkhttpd ${homerDir} --port 7424";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install = { WantedBy = [ "default.target" ]; };
    };
}
