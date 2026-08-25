{ config, lib, ... }:
{
  flake.diskoConfigurations = lib.mkMerge (
    map config.flake.lib.host.mkDisko (config.flake.lib.host.expandHosts config.flake.lib.host.registry)
  );
}
