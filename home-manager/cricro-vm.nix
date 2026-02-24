{
  rootCfgPath,
  ...
}:
let
  home-manager-modules = rootCfgPath + "/home-manager/modules";
in
{
  imports = [
    ./default.nix
    (home-manager-modules + "/apps/cli-apps/default.nix")
    (home-manager-modules + "/apps/semester.nix")
    (home-manager-modules + "/system/default.nix")
    (home-manager-modules + "/per-home/cricro-vm.nix")
  ];
}
