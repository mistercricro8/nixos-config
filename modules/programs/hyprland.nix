# Module for handling hyprland configuration
{ inputs, ... }:
{
  flake.modules.nixos.hyprland-system =
    { pkgs, ... }:
    let
      hyprpkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      hardware.graphics.package = hyprpkgs.mesa;

      programs.hyprland = {
        enable = true;
        withUWSM = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage = pkgs.xdg-desktop-portal-hyprland;
        xwayland.enable = true;
      };
    };

  flake.modules.homeManager.hyprland =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      slib = inputs.self.lib;
      mkProviderOption = providers: slib.mkProviderOption { inherit lib providers; };
      mkConfigOption = providers: slib.mkConfigOption { inherit lib providers; };
      applyConfigProvider =
        prefix: provider:
        slib.applyConfigProvider {
          inherit
            lib
            config
            prefix
            provider
            ;
        };
    in
    {
      options.sHyprland = with lib; {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable the simplified Hyprland HM configuration module.";
        };

        config = mkOption {
          type = types.submodule {
            options.provider = mkProviderOption [ "dir" ];
          };
          default = { };
          description = "Global Hyprland configuration options.";
        };

        plugins = mkOption {
          type = types.submodule {
            options.enable = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to enable plugin loading.";
            };
            options.plugins = mkOption {
              type = types.listOf (
                types.submodule {
                  options.name = mkOption {
                    type = types.str;
                    description = "Name of the plugin.";
                  };
                  options.sourcePath = mkOption {
                    type = types.str;
                    description = "Path to the plugin .so file.";
                  };
                }
              );
              default = [ ];
              description = "List of plugins to load.";
            };
          };
          default = { };
        };

        extensions = mkOption {
          type = types.submodule {
            options = {
              waybar = mkConfigOption [
                "dir"
                "catppuccin"
              ];
              dms = mkConfigOption [ "dir" ];
            };
          };
          default = { };
          description = "Hyprland extensions configuration.";
        };
      };

      config =
        let
          cfg = config.sHyprland;
          ext = cfg.extensions;
        in
        lib.mkIf cfg.enable {
          home.packages = lib.mkMerge [
            (inputs.self.lib.filterPlatformPackages pkgs (
              with pkgs;
              [
                hyprpolkitagent
                hyprpaper
                hypridle
                hyprlock
                hyprshot
                hyprcursor
                swaynotificationcenter
                waybar
                rofi
                wl-clipboard
                cliphist
                libnotify
                catppuccin-cursors.mochaYellow
              ]
            ))

            (lib.mkIf ext.dms.enable (
              inputs.self.lib.filterPlatformPackages pkgs (
                with pkgs;
                [
                  adw-gtk3
                  libsForQt5.qt5ct
                  kdePackages.qt6ct
                ]
              )
            ))
          ];

          catppuccin.waybar = lib.mkIf (ext.waybar.enable && ext.waybar.provider == "catppuccin") {
            enable = true;
          };

          home.file = lib.mkMerge [
            (lib.mkIf (cfg.config.provider == "dir") (applyConfigProvider "hyprland" cfg.config.provider))

            (lib.mkIf (ext.waybar.enable && ext.waybar.provider == "dir") (
              applyConfigProvider "waybar" ext.waybar.provider
            ))

            (lib.mkIf (ext.dms.enable && ext.dms.provider == "dir") (
              lib.mkMerge [
                (applyConfigProvider "dms" ext.dms.provider)
                (applyConfigProvider "dms-gtk-3" ext.dms.provider)
                (applyConfigProvider "dms-gtk-4" ext.dms.provider)
                (applyConfigProvider "dms-qt5ct" ext.dms.provider)
                (applyConfigProvider "dms-qt6ct" ext.dms.provider)
              ]
            ))

            (lib.mkIf (cfg.plugins.enable) (
              lib.listToAttrs (
                map (plugin: {
                  name = ".hypr/plugins/${plugin.name}";
                  value = {
                    source = config.lib.file.mkOutOfStoreSymlink plugin.sourcePath;
                  };
                }) cfg.plugins.plugins
              )
            ))
          ];

          programs.dank-material-shell = lib.mkIf ext.dms.enable {
            enable = true;

            systemd = {
              enable = true;
              restartIfChanged = true;
            };
          };
        };
    };
}
