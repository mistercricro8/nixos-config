# Params:
#   hostname - Tailscale hostname (required)
#   useRoutingFeatures - "client" | "server" | "both" (default "client")
#   extraFlags - additional flags for tailscale up (default [])
{ inputs, lib, ... }:
{
  flake.factories.nixos."services/tailscale" =
    {
      hostname,
      hostType ? "client",
      extraFlags ? [ ],
    }:
    { config, ... }:
    {
      sops.secrets."tailscale/globalAuthKey" = {
        sopsFile = inputs.self + "/secrets/tailscale.yaml";
        format = "yaml";
      };

      networking.firewall.trustedInterfaces = lib.mkDefault [ "tailscale0" ];
      networking.firewall.allowedUDPPorts = lib.mkDefault [ 41641 ];

      services.tailscale = {
        enable = true;
        useRoutingFeatures = lib.mkDefault hostType;
        authKeyFile = config.sops.secrets."tailscale/globalAuthKey".path;
        extraUpFlags = [
          "--operator=cricro"
          "--hostname=${hostname}"
          "--login-server=${inputs.private.secrets.tailscale.loginServer}"
          "--accept-routes"
          "--reset"
        ]
        ++ extraFlags;
      };
    };
}
