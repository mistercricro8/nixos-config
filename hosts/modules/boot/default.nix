{
  pkgs,
  inputs,
  ...
}:

{
  # ------------- boot -------------
  boot = {
    loader.grub = {
      enable = true;
      device = "nodev";
      useOSProber = true;
      efiSupport = true;
      default = "saved";
      theme = pkgs.stdenv.mkDerivation {
        pname = "catppuccin-grub";
        version = "1.0";
        src = inputs.catppuccin-grub;
        installPhase = "cp -r src/catppuccin-mocha-grub-theme $out";
      };
      extraEntries = ''
        menuentry 'Reboot to Firmware Interface' {
          fwsetup
        }
      '';
    };
    loader.efi.canTouchEfiVariables = true;
    #kernelPackages = pkgs.linuxPackages;
    #kernelModules = [ "v4l2loopback" ];
    #extraModulePackages = [ pkgs.linuxPackages.v4l2loopback ];
  };

}
