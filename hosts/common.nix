{
  pkgs,
  inputs,
  lib,
  ...
}:

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

  # ------------- ssh -------------
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
  users.users.root.openssh.authorizedKeys.keys = [
    # cricro-vm
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnCUevyXnMK0jLKEEBQYSF5UoCiBQt7WZMbIo9y6/Nc root@instance-01"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPFlwEmkVmbWX2MTZtgQHQXFHqbIxc5dO4leGX1qFfI cricro@instance-01"
    # cricro-laptop-linux
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDvAdfsO6rlJw80PZwLJ8GtDKuSAb1EMa35yaBlCTcy3 root@cricro-laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQvMNCGvxpPmwxCBPiOf9o/B5tZymCRBg8Y7wgwsL57 cricro@cricro-laptop"
    # cricro-pc-windows
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICk894y0LXcl7iDLmaIkEa3SrW9NPoGHDVer+pjDen35 cricro@cricro-pc"
    # cricro-pc-linux
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCYtYcsQkILXoEtIUx0U/k5iSOxjmEWXZb4uQBiAZna root@cricro-pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWJOoS+mMH5g17O2uvmD33ZGFIz0fIhyx+8CIGUx8gP cricro@cricro-pc"
  ];

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
  virtualisation.docker = {
    enable = true;
  };
  systemd.services.docker.wantedBy = lib.mkForce [ ];

  # ------------- security -------------
  security.rtkit.enable = true;

  system.stateVersion = "24.05";
}
