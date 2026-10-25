{ inputs, ... }:
{
  flake.modules.nixos."desktop/hyprland" =
    {
      pkgs,
      ...
    }:
    let
      hyprpkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    in
    {
      imports = [
        inputs.dms.nixosModules.dank-material-shell
        inputs.dank-greeter.nixosModules.default
      ];

      programs.hyprland = {
        enable = true;
        withUWSM = true;
        package = hyprlandPkg;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        xwayland.enable = true;
      };

      hardware.graphics.package = hyprpkgs.mesa;

      dotfiles.profiles = [
        "scripts"
        "hyprland"
        "dms"
        "dms-qt6ct"
        "dms-kde"
        "backgrounds"
        "icons"
      ];

      programs.dank-material-shell = {
        enable = true;
        systemd = {
          enable = true;
          restartIfChanged = true;
        };
      };

      programs.dms-greeter = {
        enable = true;
        compositor.name = "hyprland";
        configHome = "/home/cricro";
      };

      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        config = {
          common.default = [ "gtk" ];
          hyprland.default = [
            "hyprland"
            "gtk"
          ];
        };
      };
    };

  flake.factories.nixos."desktop/hyprland" =
    {
      user ? "cricro",
    }:
    { pkgs, config, ... }:
    let
      hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    in
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs;
        [
          hyprpolkitagent
          hyprpaper
          hypridle
          hyprlock
          hyprcursor
          wl-clipboard
          cliphist
          libnotify
          catppuccin-cursors.mochaYellow
          papirus-icon-theme
          adw-gtk3
          nur.repos.ilya-fedin.qt6ct
          pywalfox-native
        ]
      );

      hjem.users.${user}.files = {
        ".config/hypr/share" = {
          source = "${hyprlandPkg}/share/hypr";
          type = "symlink";
          clobber = true;
        };
        ".config/hypr/plugins/split-monitor-workspaces" = {
          source = "${inputs.split-monitor-workspaces}";
          type = "symlink";
          clobber = true;
        };
        ".cache/wal/colors.json" = {
          source = "/home/${user}/.cache/wal/dank-pywalfox.json";
          type = "symlink";
          clobber = true;
        };
        ".config/hypr/load-env" = {
          source = config.hjem.users.${user}.environment.loadEnv;
        };
      };
    };
}
