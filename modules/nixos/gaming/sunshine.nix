{ ... }:
{
  flake.modules.nixos."gaming/sunshine" =
    { ... }:
    {
      services.sunshine = {
        enable = true;
        autoStart = false;
        capSysAdmin = true;
        openFirewall = true;
      };

      hardware.uinput.enable = true;
      users.users.cricro.extraGroups = [ "uinput" ];
    };
}
