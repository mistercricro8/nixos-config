{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ------------- sway! (not happening) -------------
  security.polkit.enable = true;
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # ------------- users -------------
  users = {
    defaultUserShell = pkgs.zsh;
    users.cricro = {
      isNormalUser = true;
      description = "Christian";
      extraGroups = [ "networkmanager" "wheel" "cdrom" ];
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
        "path" = "/home/cricro/LaEsquinaStore/laesquina-management/files";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "LaEsquina";
      };
      "Archivos" = {
        "path" = "/home/cricro/LaEsquinaStore/Archivos";
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
