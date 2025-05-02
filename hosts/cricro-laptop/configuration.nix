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

  # ------------- additional system packages -------------
  environment.systemPackages =
    with pkgs;
    commonPackages
    ++ [
      qemu
      quickemu
      libguestfs-with-appliance
      cowsay
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
  users = {
    defaultUserShell = pkgs.zsh;
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
