{ ... }:
{
  flake.modules.nixos."desktop/kde" =
    { ... }:
    {
      services.desktopManager.plasma6.enable = true;
    };
}
