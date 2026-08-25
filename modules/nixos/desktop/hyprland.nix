{ inputs, ... }:
{
  flake.modules.nixos."desktop/hyprland" =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hyprpkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    in
    {
      imports = [
        inputs.dms.nixosModules.dank-material-shell
        inputs.dms.nixosModules.greeter
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
        "dms-gtk-3"
        "dms-gtk-4"
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

      programs.dank-material-shell.greeter = {
        enable = true;
        compositor.name = "hyprland";
        # TODO: remove when dms generates lua config
        compositor.customConfig = ''
          hl.env("DMS_RUN_GREETER", "1")
        '';
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

      systemd.user.paths.dms-theme-watcher = {
        wantedBy = [ "default.target" ];
        pathConfig = {
          PathChanged = "%h/.cache/DankMaterialShell/dms-colors.json";
          Unit = "dms-theme-reload.service";
        };
      };

      systemd.user.services.dms-theme-reload = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart =
            let
              dotfileTargetDirs = lib.unique (
                lib.concatMap (
                  prefix:
                  let
                    targetDirConfig = config.dotfiles.definitions.${prefix} or null;
                  in
                  if targetDirConfig != null then [ "$HOME/${targetDirConfig.path}" ] else [ ]
                ) config.dotfiles.profiles
              );
              scriptCommands = lib.concatMapStringsSep "\n" (dir: ''
                if [ -f "${dir}/load_theme.sh" ]; then
                  echo "[dms-theme-reload] Executing ${dir}/load_theme.sh..."
                  bash "${dir}/load_theme.sh" || echo "[dms-theme-reload] ERROR: ${dir}/load_theme.sh failed with exit code $?" >&2
                fi
              '') dotfileTargetDirs;
            in
            "${pkgs.writeShellScript "reload-dms-theme" scriptCommands}";
        };
        path = with pkgs; [
          # TODO: autodeclare these from existing config-dirs?
          bash
          jq
          busybox
          bat
          fish
        ];
      };
    };

  flake.factories.nixos."desktop/hyprland" =
    {
      user ? "cricro",
    }:

    { pkgs, ... }:

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
          hyprshot
          hyprcursor
          swaynotificationcenter
          wl-clipboard
          cliphist
          libnotify
          catppuccin-cursors.mochaYellow
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
      };
    };
}
