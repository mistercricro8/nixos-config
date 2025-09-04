{ pkgs, inputs, ... }:

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

  # ------------- additional system packages -------------
  environment.systemPackages =
    with pkgs;
    commonPackages
    ++ [
      # placeholder
      cowsay
    ];

  # ------------- sway! (not happening) -------------
  security.polkit.enable = true;
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # ------------- networking -------------
  networking.hostName = "cricro-pc";
  networking.networkmanager.ensureProfiles.profiles = {
    "ethernet" = {
      connection.type = "ethernet";
      connection.id = "ethernet_1";
      connection.interface-name = "enp5s0";
      connection.autoconnect = true;
      ipv4.method = "manual";
      ipv4.addresses = "192.168.1.68/32";
      ipv4.gateway = "192.168.1.1";
      ipv4.dns = "200.48.225.130";
    };
  };

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
        "dialout"
        "cdrom"
        "docker"
      ];
      packages = with pkgs; [ ];
    };
    users.LaEsquina = {
      isNormalUser = true;
    };
  };

  # ------------- windows files D: -------------
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "security" = "user";
      };
      "files" = {
        "path" = "/home/LaEsquina/la-esquina-store/laesquina-management/files";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "LaEsquina";
      };
      "Archivos" = {
        "path" = "/home/LaEsquina/la-esquina-store/Archivos";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "LaEsquina";
      };
      "Medicina" = {
        "path" = "/home/LaEsquina/la-esquina-store/Medicina";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "LaEsquina";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # ------------- windows clears here sadly (noise supression) -------------
  programs.noisetorch.enable = true;
}
