{
  pkgs,
  config,
  rootCfgPath,
  inputs,
  ...
}:

let
  split-monitor-workspaces-hypr =
    inputs.split-monitor-workspaces.packages.${pkgs.stdenv.hostPlatform.system}.split-monitor-workspaces;

  home-manager-modules = rootCfgPath + "/home-manager/modules";
in
{
  imports = [
    ./default.nix
    (home-manager-modules + "/apps/gui-apps/default.nix")
    (home-manager-modules + "/apps/gui-apps/vscode.nix")
    (home-manager-modules + "/apps/gui-apps/zed.nix")
    (home-manager-modules + "/apps/cli-apps/default.nix")
    (home-manager-modules + "/apps/cli-apps/x86_64-only.nix")
    (home-manager-modules + "/apps/semester.nix")
    (home-manager-modules + "/fonts/default.nix")
    (home-manager-modules + "/system/default.nix")
    (home-manager-modules + "/system/for-laptops.nix")
    (home-manager-modules + "/per-home/cricro-laptop.nix")

    ./n-modules/dotfiles.nix
    ./n-modules/hyprland.nix
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

  home.file = {
    ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
    ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk}";
  };
}
