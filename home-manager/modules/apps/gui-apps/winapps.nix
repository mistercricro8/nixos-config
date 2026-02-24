{
  pkgs,
  inputs,
  ...
}:
let
  winapps-toplevel = inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = [
    winapps-toplevel.winapps
  ];
}
