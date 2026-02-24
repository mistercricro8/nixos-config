# TODO questionable module placement
{
  ...
}:

{
  # ------------- laptop networking -------------
  networking.wireless.iwd = {
    enable = true;
    settings = {
      IPv6 = {
        Enabled = true;
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };
  networking.networkmanager.wifi.backend = "iwd";
}
