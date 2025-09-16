{
  ...
}:

{
  # ------------- time -------------
  time.timeZone = "America/Lima";

  # ------------- system stuff -------------
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
  };
  system.stateVersion = "24.05";

  # ------------- networking -------------
  networking.hostName = "cricro-laptop";
}
