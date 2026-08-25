{
  inputs,
  config,
  lib,
  ...
}:
{
  # Build a NixOS system from an expanded host registry entry.
  config.flake.lib.host.mkNixos =
    {
      configName,
      name,
      system,
      diskoLayout,
      ...
    }:
    {
      ${configName} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.disko.nixosModules.disko
          (import ./_disko/${diskoLayout}.nix)
          inputs.self.modules.nixos."hosts/${name}"
          inputs.hjem.nixosModules.default
          {
            nixpkgs.hostPlatform = lib.mkDefault system;
          }
        ];
      };
    };

  # Build a deploy-rs node from an expanded host registry entry.
  config.flake.lib.host.mkDeployNode =
    {
      configName,
      system,
      deployHostname,
      sshUser ? "nixremote",
      user ? "root",
      fastConnection ? null,
      autoRollback ? null,
      magicRollback ? null,
      remoteBuild ? null,
      sshOpts ? null,
      sudo ? null,
      profilesOrder ? null,
      tempPath ? null,
      activationTimeout ? null,
      confirmTimeout ? null,
      groups ? null,
      ...
    }:
    let
      cleanAttrs = lib.filterAttrs (_: v: v != null);
      nodeOpts = cleanAttrs {
        hostname = deployHostname;
        inherit
          sshUser
          fastConnection
          autoRollback
          magicRollback
          remoteBuild
          sshOpts
          sudo
          profilesOrder
          tempPath
          activationTimeout
          confirmTimeout
          groups
          ;
        profiles.system = cleanAttrs {
          inherit user;
          path = inputs.deploy-rs.lib.${system}.activate.nixos config.flake.nixosConfigurations.${configName};
        };
      };
    in
    {
      ${configName} = nodeOpts;
    };

  # Build a diskoConfiguration from an expanded host registry entry.
  config.flake.lib.host.mkDisko =
    { configName, diskoLayout, ... }:
    {
      ${configName} = import ./_disko/${diskoLayout}.nix;
    };
}
