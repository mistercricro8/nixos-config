{ ... }:
{
  flake.modules.nixos."system/settings/peripherals" =
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
