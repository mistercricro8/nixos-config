{
  rootCfgPath,
  pkgs,
  ...
}:

let
  nixos-modules = rootCfgPath + "/hosts/modules";
in
{
  imports = [
    ./default.nix
    #(nixos-modules + "/boot/default.nix")
    (nixos-modules + "/desktops/hyprland.nix")
    (nixos-modules + "/desktops/kde.nix")
    (nixos-modules + "/hardware/cricro-laptop.nix")
    (nixos-modules + "/overlays/default.nix")
    (nixos-modules + "/peripherals/default.nix")
    (nixos-modules + "/peripherals/for-laptops.nix")
    (nixos-modules + "/steam/default.nix")

    ./n-modules/samba.nix
    ./n-modules/boot.nix
    ./n-modules/tailscale.nix
  ];

  # ------------- boot -------------
  sBoot = {
    enable = true;
  };

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "cricro" ];
  programs.wireshark = {
    enable = true;
    dumpcap.enable = true;
    usbmon.enable = true;
  };
  users.extraGroups.wireshark.members = [ "cricro" ];

  # ------------- samba -------------
  sSamba = {
    enable = false;
    dirs = {
      "datafest" = {
        path = "/home/datafest/datafest";
        guestOk = "no";
        writable = "yes";
        accessMode = "read-write";
        user = "datafest";
        userData = {
          homeMode = "0777";
          hashedPassword = "$y$j9T$l/PxxMweO25/XtIUHR6Kf/$lML0xzPUPhR7XB1kfKgfAVH.1qfCzjvh0vi6azQjR4/";
        };
      };
    };
  };

  # ------------- access point -------------
  environment.systemPackages = with pkgs; [
    wireshark-qt
    linux-wifi-hotspot
  ];

  # ------------- hell -------------
  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];

  networking.firewall = {
    allowedTCPPorts = [
      8786
      8787
      9004
      9005
    ];
    allowedUDPPorts = [
      8786
      8787
      9004
      9005
    ];
  };

  #  services.create_ap = {
  #    enable = true;
  #    settings = {
  #      INTERNET_IFACE = "enp2s0";
  #      PASSPHRASE = "88888888";
  #      SSID = "wa";
  #      WIFI_IFACE = "wlan0";
  #      ISOLATE_CLIENTS = 0;
  #    };
  #  };

  # ------------- time -------------
  time.timeZone = "America/Lima";

  # ------------- vpn -------------
  sTailscale = {
    enable = true;
    hostName = "cricro-laptop";
  };

  # ------------- docker -------------
  virtualisation.docker.enableOnBoot = false;

  # ------------- system stuff -------------
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
  };
  system.stateVersion = "24.05";
}
