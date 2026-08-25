{ inputs, ... }:
{
  flake.modules.nixos."users/nixremote" =
    {
      config,
      pkgs,
      ...
    }:
    {
      users.users.nixremote = {
        isSystemUser = true;
        group = "nixremote";
        createHome = false;
        home = "/var/empty";
        shell = pkgs.bash;
        hashedPassword = "*";
        openssh.authorizedKeys.keys = config.systemConstants.sshConfig.ownKeys;
      };

      users.groups.nixremote = { };

      security.sudo.extraRules = [
        {
          users = [ "nixremote" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };
}
