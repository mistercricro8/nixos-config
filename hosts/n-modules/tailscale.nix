{
  lib,
  config,
  customLib,
  rootCfgPath,
  ...
}:

let
  private = customLib.private;
in
{
  options.sTailscale = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the simplified tailscale configuration module.";
    };
    hostName = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "Hostname to use for tailscale.";
    };
    hostType = mkOption {
      type = types.enum [
        "client"
        "server"
        "both"
      ];
      default = "client";
      description = "Type of host for tailscale routing features.";
    };
  };

  config =
    let
      cfg = config.sTailscale;
    in
    lib.mkIf cfg.enable {
      sops.secrets."tailscale/authKeys/${cfg.hostName}" = {
        sopsFile = rootCfgPath + "/secrets/tailscale.yaml";
        format = "yaml";
      };

      services.tailscale = {
        enable = true;
        useRoutingFeatures = cfg.hostType;
        authKeyFile = "/run/secrets/tailscale/authKeys/${cfg.hostName}";
        extraUpFlags = lib.mkMerge [
          [
            "--operator=cricro"
            "--hostname=${cfg.hostName}"
            "--login-server=${private.tailscale.loginServer}"
            "--exit-node-allow-lan-access"
          ]
          (lib.mkIf (cfg.hostType == "server" || cfg.hostType == "both") [
            "--advertise-exit-node"
            "--advertise-tags=tag:exit"
          ])
        ];
      };

    };
}
