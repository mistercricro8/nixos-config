{
  pkgs,
  config,
  rootCfgPath,
  rootCfgPathAbs,
  inputs,
  lib,
  ...
}:
let
  split-monitor-workspaces-hypr =
    inputs.split-monitor-workspaces.packages.${pkgs.stdenv.hostPlatform.system}.split-monitor-workspaces;

  storeDir = config.home.homeDirectory + "/store";
  storeDirs = [
    "uni"
    "repos"
    "tiny-projects"
    "videos"
    "projects"
    "important"
  ];

  homeUtils = import ./home-utils.nix {
    inherit
      config
      lib
      rootCfgPath
      rootCfgPathAbs
      ;
  };
  mkSelectedFiles = homeUtils.mkSelectedFiles;
  home-manager-modules = rootCfgPath + "/home-manager/modules";
in
{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak

    ./default.nix
    (home-manager-modules + "/apps/gui-apps/default.nix")
    (home-manager-modules + "/apps/gui-apps/vscode.nix")
    (home-manager-modules + "/apps/gui-apps/zed.nix")
    (home-manager-modules + "/apps/gui-apps/winapps.nix")
    (home-manager-modules + "/apps/cli-apps/default.nix")
    (home-manager-modules + "/apps/cli-apps/x86_64-only.nix")
    (home-manager-modules + "/apps/semester.nix")
    (home-manager-modules + "/fonts/default.nix")
    (home-manager-modules + "/system/default.nix")
    (home-manager-modules + "/per-home/cricro-pc.nix")

    ./n-modules/hyprland.nix
    ./n-modules/dotfiles.nix
  ];

  services.flatpak.packages = [
    "org.vinegarhq.Sober"
  ];

  sDotfiles = {
    enable = true;
    configs = {
      backgrounds.enable = true;
      bottom.enable = true;
      kitty.enable = true;
      rofi.enable = true;
      swaync.enable = true;
      vscode.enable = true;
      zed.enable = true;
      winapps.enable = true;
      xsettingsd.enable = true;
      yazi.enable = true;
      mimeapps.enable = true;
      starship.enable = true;
    };
  };

  sHyprland = {
    enable = true;
    extensions = {
      dms.enable = true;
    };
    plugins = {
      enable = true;
      plugins = [
        {
          name = "libsplit-monitor-workspaces.so";
          sourcePath = "${split-monitor-workspaces-hypr}/lib/libsplit-monitor-workspaces.so";
        }
      ];
    };
  };

  home.sessionVariables = {
    # TODO: this was here to fix some app not launching, cant find which
    # kdenlive maybe
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}";
  };

  home.file = (
    (mkSelectedFiles storeDir storeDirs ".")
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}"; # TODO test gtk.cursorTheme
      ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk}";
    }
  );
}
