{
  pkgs,
  customLib,
  ...
}:

let
  sshConfig = customLib.constants.sshConfig;
in
{
  # ------------- remote building -------------
  # TODO does this declaration override the other one or merge to it?
  nix.settings.trusted-users = [ "nixremote" ];

  boot.binfmt.emulatedSystems = pkgs.lib.filter (system: system != pkgs.stdenv.hostPlatform.system) [
    "x86_64-linux"
    "aarch64-linux"
  ];
  users.users.nixremote = {
    description = "Remote builds user";
    isNormalUser = true;
    openssh.authorizedKeys.keys = sshConfig.buildKeys;
    homeMode = "500";
  };
}
