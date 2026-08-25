# Params:
#   netInterfaces - list of interface names (e.g. ["enp3s0" "wlan0"])
#   ipv6          - enable IPv6 (default true)
#   wakeonlan     - enable WoL on all netInterfaces (default false)
#   nftables      - enable nftables (default false)
#   profiles      - attrset of NetworkManager ensureProfiles.profiles
{ ... }:
{
  flake.factories.nixos."system/settings/networking" =
    {
      netInterfaces ? [ ],
      ipv6 ? true,
      wakeonlan ? false,
      nftables ? false,
      profiles ? { },
    }:
    { lib, ... }:
    {
      networking = {
        nftables.enable = nftables;
        enableIPv6 = lib.mkDefault ipv6;
        networkmanager.ensureProfiles.profiles = profiles;
        firewall.trustedInterfaces = lib.mkDefault [ "tailscale0" ];
        interfaces = lib.genAttrs netInterfaces (iface: {
          wakeOnLan.enable = wakeonlan && (lib.hasPrefix "en" iface);
        });
      };
    };
}
