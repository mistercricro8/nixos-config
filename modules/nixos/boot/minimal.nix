{ ... }:
{
  flake.modules.nixos."boot/minimal" =
    { ... }:
    {
      boot.loader.grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
      boot.loader.efi.canTouchEfiVariables = true;
    };
}
