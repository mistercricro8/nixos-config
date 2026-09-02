{ inputs, ... }:
{
  flake.factories.nixos."secrets/ssh-keys" =
    {
      user ? "cricro",
      keys ? [ "id_ed25519" ],
      host ? null,
    }:
    { config, lib, ... }:
    let
      hostName = if host != null then host else config.networking.hostName;
      userHome = config.users.users.${user}.home;
      userGroup = config.users.users.${user}.group;
      sshSecretFile = inputs.self + "/secrets/ssh.yaml";

      normalizeKey =
        k:
        if builtins.isString k then
          {
            name = k;
            shared = false;
          }
        else
          {
            name = k.name;
            shared = k.shared or false;
          };

      normalizedKeys = map normalizeKey keys;
    in
    {
      sops.secrets = lib.listToAttrs (
        map (k: {
          name = "ssh-${k.name}";
          value = {
            sopsFile = sshSecretFile;
            key =
              if k.shared then
                "users/${user}/${k.name}"
              else
                "users/${user}/hosts/${hostName}/${k.name}";
            path = "${userHome}/.ssh/${k.name}";
            owner = user;
            group = userGroup;
            mode = "0600";
          };
        }) normalizedKeys
      );

      hjem.users.${user}.files = lib.listToAttrs (
        map (k: {
          name = ".ssh/${k.name}.pub";
          value = {
            source =
              if k.shared then
                inputs.self + "/keys/${k.name}.pub"
              else
                inputs.self + "/keys/${hostName}/${k.name}.pub";
            clobber = true;
          };
        }) normalizedKeys
      );
    };
}
