{
  config,
  lib,
  inputs,
  ...
}:
let
  hosts = config.flake.lib.host.expandHosts config.flake.lib.host.registry;
in
{
  flake.deploy.nodes = lib.mergeAttrsList (map config.flake.lib.host.mkDeployNode hosts);

  flake.checks = lib.mkMerge (
    map (
      system:
      if inputs.deploy-rs.lib ? ${system} then
        {
          ${system} = inputs.deploy-rs.lib.${system}.deployChecks config.flake.deploy;
        }
      else
        { }
    ) config.systems
  );
}
