{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ------------- jk yes vpn -------------
  networking.wg-quick.interfaces.wg0.configFile = "/etc/wireguard/cricro-laptop-linux.conf";

  # ------------- networking -------------
  networking.hostName = "cricro-laptop";

  # ------------- laptop networking -------------
  networking.wireless.iwd = {
    enable = true;
    settings = {
      IPv6 = { Enabled = true; };
      Settings = { AutoConnect = true; };
    };
  };
  networking.networkmanager.wifi.backend = "iwd";

  # ------------- users -------------
  users = {
    defaultUserShell = pkgs.zsh;
    users.cricro = {
      isNormalUser = true;
      description = "Christian";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [ ];
    };
  };
}
