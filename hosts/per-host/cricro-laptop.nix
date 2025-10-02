{
  rootCfgPath,
  ...
}:

let
  nixos-modules = rootCfgPath + "/hosts/modules";
in
{
  imports = [
    ../default.nix
    (nixos-modules + "/boot/default.nix")
    (nixos-modules + "/desktops/hyprland.nix")
    (nixos-modules + "/desktops/kde.nix")
    (nixos-modules + "/hardware/cricro-laptop.nix")
    (nixos-modules + "/overlays/default.nix")
    (nixos-modules + "/peripherals/default.nix")
    (nixos-modules + "/peripherals/for-laptops.nix")
    (nixos-modules + "/steam/default.nix")
    (nixos-modules + "/vpn/default.nix")
  ];

  # ------------- time -------------
  time.timeZone = "America/Lima";

  # ------------- vpn -------------
  services.tailscale.useRoutingFeatures = "client";

  # ------------- docker -------------
  virtualisation.docker.enableOnBoot = false;

  # ------------- system stuff -------------
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
  };
  system.stateVersion = "24.05";

  # ------------- networking -------------
  networking.hostName = "cricro-laptop";
}
