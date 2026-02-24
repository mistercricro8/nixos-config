{
  ...
}:

{
  # ------------- printing -------------
  services.printing.enable = true;

  # ------------- keyboard -------------
  # just enaled, hyprland can manage it
  services.xserver.enable = true;

  # ------------- audio/video -------------
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
}
