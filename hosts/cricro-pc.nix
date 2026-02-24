{
  rootCfgPath,
  pkgs,
  config,
  ...
}:

let
  nixos-modules = rootCfgPath + "/hosts/modules";
in
{
  imports = [
    ./default.nix
    #(nixos-modules + "/boot/default.nix")
    #(nixos-modules + "/builder/default.nix")
    (nixos-modules + "/desktops/hyprland.nix")
    (nixos-modules + "/desktops/kde.nix")
    (nixos-modules + "/hardware/cricro-pc.nix")
    (nixos-modules + "/overlays/default.nix")
    (nixos-modules + "/peripherals/default.nix")
    (nixos-modules + "/sunshine/default.nix")
    (nixos-modules + "/steam/default.nix")

    ./n-modules/samba.nix
    ./n-modules/boot.nix
    ./n-modules/tailscale.nix
  ];

  # this was for winapps?
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "cricro" ];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  # no clue
  programs.dconf.enable = true;

  # droidcam, altho droidcam.enable apparently already does this
  programs.droidcam.enable = true;
  boot.kernelModules = [
    "v4l2loopback"
    "snd-aloop"
  ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

  # programs.wireshark = {
  #   enable = true;
  #   dumpcap.enable = true;
  #   usbmon.enable = true;
  # };
  # users.extraGroups.wireshark.members = [ "cricro" ];
  environment.systemPackages = with pkgs; [
    v4l-utils
  ];

  services.flatpak.enable = true;

  # ------------- boot -------------
  sBoot = {
    enable = true;
  };

  # ------------- samba -------------
  sSamba = {
    enable = true;
    dirs = {
      "files" = {
        path = "/home/LaEsquina/la-esquina-store/laesquina-management/files";
        guestOk = "no";
        writable = "yes";
        accessMode = "read-write";
        user = "LaEsquina";
        userData = {
          homeMode = "0777";
          hashedPassword = "$y$j9T$Fm/3aDe8MkmxKAX16PhK/0$sVt5FWmeQJbOkTFHQhT0DCqC3bti13ORbx/MiwDFXB2";
        };
      };
      "Archivos" = {
        path = "/home/LaEsquina/la-esquina-store/Archivos";
        guestOk = "no";
        writable = "yes";
        accessMode = "read-write";
        user = "LaEsquina";
      };
      "Medicina" = {
        path = "/home/LaEsquina/la-esquina-store/Medicina";
        guestOk = "no";
        writable = "yes";
        accessMode = "read-write";
        user = "LaEsquina";
      };
    };
  };

  # ------------- time -------------
  time.timeZone = "America/Lima";

  # ------------- vpn -------------
  sTailscale = {
    enable = true;
    hostName = "cricro-pc-l";
  };

  # ------------- system stuff -------------
  system.stateVersion = "24.05";

  # ------------- networking -------------
  # TODO: wol config module
  networking.interfaces.enp5s0.wakeOnLan.enable = true;

  # ------------- docker -------------
  virtualisation.docker.enableOnBoot = false;

  # ------------- noise suppression -------------
  # okay so my argument to not put this in a separate module is that i only have one
  # pc with awful microphone :>
  programs.noisetorch.enable = true;
}
