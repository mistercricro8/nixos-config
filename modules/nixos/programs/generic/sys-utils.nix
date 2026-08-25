{ inputs, ... }:
{
  flake.modules.nixos."programs/generic/sys-utils" =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs;
        [
          nmap
          smartmontools
          pulseaudio
          lsof
          dig
          net-tools
          lm_sensors
          usbutils
          iotop
        ]
      );
    };
}
