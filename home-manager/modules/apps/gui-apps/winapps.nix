{
  pkgs,
  inputs,
  ...
}:
let
  winapps-toplevel = inputs.winapps.packages.${pkgs.system};
in
{
  home.packages = [
    winapps-toplevel.winapps
  ];
}
