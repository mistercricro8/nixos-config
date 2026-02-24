{
  lib,
  config,
  ...
}:

let
  masks = {
    "read-only" = {
      createMask = "0744";
      directoryMask = "0755";
    };
    "read-write" = {
      createMask = "0766";
      directoryMask = "0777";
    };
  };
in
{
  options.sSamba = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the simplified samba configuration module.";
    };
    tailscaleOnly = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to only bind to tailscale.";
    };
    dirs = mkOption {
      type = types.attrsOf (
        types.submodule {
          options.path = mkOption {
            type = types.str;
            description = "Path to share.";
          };
          options.guestOk = mkOption {
            type = types.enum [
              "yes"
              "no"
            ];
            default = "no";
            description = "Whether to allow guest access.";
          };
          options.accessMode = mkOption {
            type = types.enum [
              "read-only"
              "read-write"
            ];
            default = "read-only";
            description = "Access mode for the share.";
          };
          options.browseable = mkOption {
            type = types.enum [
              "yes"
              "no"
            ];
            default = "yes";
            description = "Whether the share is browseable.";
          };
          options.writable = mkOption {
            type = types.enum [
              "yes"
              "no"
            ];
            default = "no";
            description = "Whether the share is writable.";
          };

          options.user = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Username to use as file owner / `force user`.";
          };

          options.userData = mkOption {
            type = types.nullOr (
              types.submodule {
                options.homeMode = mkOption {
                  type = types.str;
                  default = "0755";
                  description = "Home directory mode for the user.";
                };
                options.hashedPassword = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Hashed password for the user (use `mkpasswd`).";
                };
              }
            );
            default = null;
            description = "If set (together with `user`) a system user will be created using these fields.";
          };
        }
      );
      default = { };
      description = "Directories to share over Samba.";
    };
  };

  config =
    let
      cfg = config.sSamba;

      mkUserConfig =
        username: userData:
        lib.mkMerge [
          {
            isNormalUser = true;
            homeMode = userData.homeMode;
          }
          (lib.mkIf (userData.hashedPassword != null) {
            hashedPassword = userData.hashedPassword;
          })
        ];

      userEntries = builtins.concatLists (
        map (
          dir:
          if dir.userData != null then
            [
              {
                name = dir.user;
                value = mkUserConfig dir.user dir.userData;
              }
            ]
          else
            [ ]
        ) (builtins.attrValues cfg.dirs)
      );
    in
    lib.mkIf cfg.enable {
      services.samba = {
        enable = true;
        openFirewall = true;
        nmbd.enable = false;
        settings = lib.mkMerge [
          {
            global = {
              "workgroup" = "WORKGROUP";
              "security" = "user";
              "bind interfaces only" = lib.mkIf cfg.tailscaleOnly "yes";
              "interfaces" = lib.mkIf cfg.tailscaleOnly "lo";
              "smb ports" = lib.mkIf cfg.tailscaleOnly "445";
            };
          }
          (lib.mapAttrs (
            _name: dirCfg:
            let
              chosenMasks = masks.${dirCfg.accessMode};
            in
            {
              "path" = dirCfg.path;
              "guest ok" = dirCfg.guestOk;
              "create mask" = chosenMasks.createMask;
              "browseable" = dirCfg.browseable;
              "writable" = dirCfg.writable;
              "directory mask" = chosenMasks.directoryMask;
              "force user" = lib.mkIf (dirCfg.user != null) dirCfg.user;
            }
          ) cfg.dirs)
        ];
      };

      systemd.services.tailscale-samba-proxy = lib.mkIf cfg.tailscaleOnly {
        description = "Tailscale Serve Proxy for Samba";
        after = [
          "network-online.target"
          "tailscaled.service"
          "samba-smbd.service"
        ];
        wants = [
          "network-online.target"
          "tailscaled.service"
          "samba-smbd.service"
        ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --tcp 445 tcp://localhost:445";
          ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --tcp 445 off";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      users.users = builtins.listToAttrs userEntries;

      services.samba-wsdd = {
        enable = true;
        openFirewall = true;
      };
    };
}
