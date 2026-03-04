# Configuration for common peripherals
{ ... }:
{
  flake.modules.nixos.peripherals =
    { ... }:
    {
      services.printing.enable = true;

      services.xserver.enable = true;

      services.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
    };
}
