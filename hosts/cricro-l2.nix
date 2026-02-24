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
    (nixos-modules + "/builder/default.nix")
    (nixos-modules + "/hardware/cricro-l2.nix")
    (nixos-modules + "/peripherals/for-laptops.nix")
    (nixos-modules + "/overlays/default.nix")

    ./n-modules/boot.nix
    ./n-modules/tailscale.nix
  ];

  # ------------- time -------------
  time.timeZone = "America/Lima";

  # ------------- vpn -------------
  sTailscale = {
    enable = true;
    hostName = "cricro-l2";
  };

  # ------------- boot -------------
  sBoot = {
    enable = true;
  };

  # ------------- system stuff -------------
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
  };
  system.stateVersion = "24.05";
}
