{
  pkgs,
  rootCfgPath,
  ...
}:

let
  ssh-config = import (rootCfgPath + "/constants/ssh.nix") { };
in
{
  # ------------- remote building -------------
  # TODO does this declaration override the other one or merge to it?
  nix.settings.trusted-users = [ "nixremote" ];

  boot.binfmt.emulatedSystems = pkgs.lib.filter (system: system != pkgs.system) [ "x86_64-linux" "aarch64-linux" ];
  users.users.nixremote = {
    description = "Remote builds user";
    isNormalUser = true;
    openssh.authorizedKeys.keys = ssh-config.build-authorized-keys;
    homeMode = "500";
  };
}
