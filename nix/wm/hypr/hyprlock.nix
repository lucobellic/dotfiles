{ pkgs, config, ... }:

# For non-nixos systems
#
# /etc/pam.d/hyprlock
# auth include login
# auth sufficient pam_sss.so
# auth required pam_unix.so
#
# sudo mkdir -pv /run/wrappers/bin/ && sudo ln -svf /sbin/unix_chkpwd /run/wrappers/bin/unix_chkpwd

let
  # https://github.com/nix-community/home-manager/issues/7027
  # https://github.com/hyprwm/hyprlock/issues/135
  hyprlockWithSystemPam = pkgs.hyprlock.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.patchelf ];
    postFixup = ''
      file="$out/bin/hyprlock"
        patchelf --replace-needed libpam.so.0 /usr/lib/x86_64-linux-gnu/libpam.so.0 "$file"
        patchelf --add-needed /usr/lib/x86_64-linux-gnu/libpam_misc.so.0 "$file"
        patchelf --add-needed /usr/lib/x86_64-linux-gnu/libpamc.so.0 "$file"
        patchelf --add-needed /usr/lib/x86_64-linux-gnu/libaudit.so.1 "$file"
        patchelf --add-needed /usr/lib/x86_64-linux-gnu/libcap-ng.so.0 "$file"
        patchelf --add-needed /usr/lib/x86_64-linux-gnu/libcrypt.so.1 "$file"
        patchelf --add-needed /usr/lib/x86_64-linux-gnu/libpwquality.so.1 "$file"
        patchelf --add-needed /usr/lib/x86_64-linux-gnu/libcrack.so.2 "$file"
    '';
  });
in {
  home.packages = [ (config.lib.nixGL.wrap hyprlockWithSystemPam) ];
}
