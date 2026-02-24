{
  lib,
  config,
  ...
}:
{
  options.sBoot = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the simplified boot configuration module.";
    };
    mode = mkOption {
      type = types.enum [
        "minimal"
        "full"
      ];
      default = "full";
      description = "Boot predefined config to use.";
    };
  };

  config =
    let
      cfg = config.sBoot;
    in
    lib.mkIf cfg.enable {
      boot.loader.grub =
        if (cfg.mode == "full") then
          {
            enable = true;
            device = "nodev";
            useOSProber = true;
            efiSupport = true;
            default = "saved";
            extraEntries = ''
              menuentry 'Reboot to Firmware Interface' {
                fwsetup
              }
            '';
          }
        else
          {
            enable = true;
            efiSupport = true;
            device = "nodev";
          };

      catppuccin.grub = lib.mkIf (cfg.mode == "full") {
        enable = true;
      };

      boot.loader.efi.canTouchEfiVariables = true;
    };
}
