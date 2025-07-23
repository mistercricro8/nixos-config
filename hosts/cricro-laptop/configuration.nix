{
  pkgs,
  ...
}:

let
  commonPackages = import ../common-packages.nix { inherit pkgs; };
in
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  # ------------- jk yes vpn -------------
  services.tailscale.enable = true;
  networking.firewall.checkReversePath = "loose";

  # ------------- networking -------------
  networking.hostName = "cricro-laptop";

  # ------------- steam -------------
  programs.steam = {
    enable = true;
  };

  # ------------- acpi -------------
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';

  # ------------- additional system packages -------------
  environment.systemPackages =
    with pkgs;
    commonPackages
    ++ [
      qemu
      quickemu
      libguestfs-with-appliance
    ];

  # ------------- laptop networking -------------
  networking.wireless.iwd = {
    enable = true;
    settings = {
      IPv6 = {
        Enabled = true;
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };
  networking.networkmanager.wifi.backend = "iwd";

  # ------------- users -------------
  programs.fish.enable = true;
  users = {
    defaultUserShell = pkgs.fish;
    users.cricro = {
      isNormalUser = true;
      description = "Christian";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [ ];
    };
  };
}
