{ inputs, ... }:
{
  flake.modules.nixos."boot/full" =
    { ... }:
    {
      boot.loader.grub = {
        enable = true;
        device = "nodev";
        useOSProber = true;
        efiSupport = true;
        default = "saved";
        theme = "${inputs.catppuccin-grub}/src/catppuccin-mocha-grub-theme";
        extraEntries = ''
          menuentry 'Reboot to Firmware Interface' {
            fwsetup
          }
        '';
      };
      boot.loader.efi.canTouchEfiVariables = true;
    };
}
