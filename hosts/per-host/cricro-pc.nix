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
    (nixos-modules + "/builder/default.nix")
    (nixos-modules + "/desktops/hyprland.nix")
    (nixos-modules + "/desktops/sddm.nix")
    (nixos-modules + "/hardware/cricro-pc.nix")
    (nixos-modules + "/overlays/default.nix")
    (nixos-modules + "/peripherals/default.nix")
    (nixos-modules + "/vpn/default.nix")
  ];

  # ------------- time -------------
  time.timeZone = "America/Lima";

  # ------------- vpn -------------
  services.tailscale.useRoutingFeatures = "client";

  # ------------- system stuff -------------
  system.stateVersion = "24.05";

  # ------------- networking -------------
  networking.hostName = "cricro-pc";

  # ------------- other users -------------
  users.users.LaEsquina = {
    isNormalUser = true;
  };

  # ------------- windows files -------------
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

  # ------------- noise suppression -------------
  # okay so my argument to not put this in a separate module is that i only have one
  # pc with awful microphone :>
  programs.noisetorch.enable = true;
}
