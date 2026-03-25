# Module for handling tailscale configuration.
{ inputs, ... }:
{
  flake.modules.nixos.sTailscale =
    { lib, config, ... }:
    {
      imports = [ inputs.self.modules.nixos.sops ];

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
          sops.secrets."tailscale/globalAuthKey" = {
            sopsFile = inputs.self + "/secrets/tailscale.yaml";
            format = "yaml";
          };

          networking.firewall.trustedInterfaces = lib.mkIf (cfg.hostType == "server" || cfg.hostType == "both") [ "tailscale0" ];

          services.tailscale = {
            enable = true;
            useRoutingFeatures = cfg.hostType;
            authKeyFile = "/run/secrets/tailscale/globalAuthKey";
            extraUpFlags = lib.mkMerge [
              [
                "--operator=cricro"
                "--hostname=${cfg.hostName}"
                "--login-server=${inputs.private.secrets.tailscale.loginServer}"
                "--accept-routes"
                "--accept-dns=true"
                "--reset"
              ]
              (lib.mkIf (cfg.hostType == "server" || cfg.hostType == "both") [
                "--advertise-exit-node"
                # for some reason broken on headscale latest
                # "--advertise-tags=tag:exit"
              ])
            ];
          };
        };
    };
}
