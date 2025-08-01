{ pkgs, inputs, ... }:

let
  hyprpkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system};
in
{
  # ------------- boot and stuffs -------------
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
    kernelPackages = pkgs.linuxPackages;
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = [ pkgs.linuxPackages.v4l2loopback ];
  };

  # ------------- hardware -------------
  hardware = {
    graphics = {
      package = hyprpkgs.mesa;
    };
  };

  # ------------- nix store -------------
  nix.settings.trusted-users = [
    "root"
    "cricro"
  ];

  # ------------- networking -------------
  networking.networkmanager.enable = true;

  # ------------- oh so great flakes -------------
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  # ------------- hyprland -------------
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };

  # ------------- time -------------
  time.timeZone = "America/Lima";
  time.hardwareClockInLocalTime = true;
  i18n.defaultLocale = "en_US.UTF-8";

  # ------------- sddm -------------
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;

  # ------------- keyboard stuff -------------
  console.keyMap = "la-latin1";
  # just have it so hyprland can manage it?
  services.xserver.enable = true;

  # ------------- printing stuff -------------
  services.printing.enable = true;

  # ------------- audio/video stuff -------------
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # jack.enable = true;
  };

  # ------------- very very important -------------
  # nixpkgs.config.allowUnfree = true;

  # ------------- programs!! -------------
  # programs.firefox.enable = true;
  services.locate.enable = true;

  # ------------- docker -------------
  virtualisation.podman = {
    enable = true;
  };

  # ------------- security -------------
  security.rtkit.enable = true;

  system.stateVersion = "24.05";
}
