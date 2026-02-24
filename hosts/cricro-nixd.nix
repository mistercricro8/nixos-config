{
  rootCfgPath,
  ...
}:
let
  nixos-modules = rootCfgPath + "/hosts/modules";
in
{
  imports = [
    ./default.nix
    (nixos-modules + "/overlays/default.nix")
    ./n-modules/boot.nix
    ./n-modules/samba.nix
    ./n-modules/tailscale.nix
  ];
  sBoot.enable = false;
  sSamba.enable = false;
  sTailscale.enable = false;
}
