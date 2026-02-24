# bootstrap configuration to get gpg working for git-crypt
# this should not import ./default.nix in the case secrets ever get in the default configuration

{
  customLib,
  pkgs,
  ...
}:
let
  sshConfig = customLib.constants.sshConfig;
in
{
  imports = [
    ./modules/hardware/bootstrap.nix
  ];

  # requirement for git-crypt
  programs.gnupg.agent.enable = true;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "cricro"
    ];
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  time.hardwareClockInLocalTime = true;
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  users.users.cricro = {
    isNormalUser = true;
    description = "";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "cdrom"
      "docker"
    ];
    packages = [ ];
    initialHashedPassword = "$y$j9T$RazGk8052EF4mQC2UYWA5/$KBvZpKyhxrZoFzM13c7y6i./096sDAQZ1FO3qL.ecX.";
    openssh.authorizedKeys.keys = sshConfig.ownKeys;
  };

  services.locate.enable = true;

  virtualisation.docker = {
    enable = true;
  };
  security.rtkit.enable = true;
}
