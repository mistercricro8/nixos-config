{ lib, ... }:
{
  # Filter a list of packages by whether they are supported on the given host platform.
  config.flake.lib.util.filterInvalidPackages =
    pkgs: packages:
    lib.filter (
      p:
      let
        res = builtins.tryEval p.drvPath;
      in
      res.success
    ) packages;
}
