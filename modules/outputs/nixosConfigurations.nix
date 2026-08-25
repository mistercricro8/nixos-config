{ config, lib, ... }:
let
  hosts = config.flake.lib.host.expandHosts config.flake.lib.host.registry;
in
{
  flake.nixosConfigurations = lib.mkMerge (map config.flake.lib.host.mkNixos hosts);
}
