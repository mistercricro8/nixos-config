# Turns a host into a builder
{ ... }:
{
  flake.modules.nixos.builder =
    { pkgs, config, ... }:
    {
      nix.settings.trusted-users = [ "nixremote" ];

      boot.binfmt.emulatedSystems = pkgs.lib.filter (system: system != pkgs.stdenv.hostPlatform.system) [
        "x86_64-linux"
        "aarch64-linux"
      ];

      users.users.nixremote = {
        description = "Remote builds user";
        isNormalUser = true;
        openssh.authorizedKeys.keys = config.systemConstants.sshConfig.buildKeys;
        homeMode = "500";
      };
    };
}
