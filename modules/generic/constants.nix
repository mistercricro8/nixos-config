{ ... }:
let
  buildKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCYtYcsQkILXoEtIUx0U/k5iSOxjmEWXZb4uQBiAZna root@cricro-pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBOP5Kv1zW6Pebs29u7yzJS73VtnkkdVGr5yz7ydlAZ0 root@cricro-vm"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJyzkR8auawdWuIKq7Yrp0kFz/+nfvDKeli4lF+mgfQ root@cricro-laptop"
  ];
  ownKeys = [
    # linux
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByLTkWDeknXUXuY3Pn47znJ0OOCBDCBZuZH5Q0tFsFr cricro@cricro-pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFemLgqTdnfq/P4v+lkh0XpFhGAyLlD6hwKAUNLeWq4D cricro@cricro-vm"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQvMNCGvxpPmwxCBPiOf9o/B5tZymCRBg8Y7wgwsL57 cricro@cricro-laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElGKqHU3uf9R8bBc8eyAV5/ScVmCw/MP8JgOOAXXSqB cricro@cricro-l2"

    # windows
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhKGamcAqDuwcnGr/edN8cGfzgsWoO+SZnT6l3tVh1F cricro@cricro-pc"

    # android
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATB/aYqhhK/3O4G0NXvlySGDQudDWRUUO/QEbj6rUy5 u0_a361@localhost"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwZZhjpbVwnQRKzTe9ai1sOa+Vi+91pK4VawPmBstxF u0_a253@localhost"
  ];
  otherKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLTHf+kUZZ2hGnox98CgxS4s261huPjL0RPm1yJKHa7 lenovo@USER" # ryan
  ];
in
{
  flake.lib.constants = {
    rootCfgPathAbs = "/home/cricro/nixos-config";
  };

  flake.modules.generic.constants =
    { lib, ... }:
    {
      options.systemConstants = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified;
        default = { };
      };

      config.systemConstants.sshConfig = {
        buildKeys = buildKeys;
        ownKeys = buildKeys ++ ownKeys;
        allKeys = buildKeys ++ ownKeys ++ otherKeys;
      };
    };
}
