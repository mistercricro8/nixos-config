{ ... }:
{
  flake.modules.generic.system-constants =
    { lib, ... }:
    {
      config.systemConstants = {
        configName = lib.mkDefault "";
        rootCfgPathAbs = lib.mkDefault "/home/cricro/nixos-config";
      };
    };
}
