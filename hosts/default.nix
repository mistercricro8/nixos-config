{
  pkgs,
  rootCfgPath,
  ...
}:

let
  mkBuildMachine = hostName: {
    hostName = hostName;
    sshUser = "nixremote";
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    protocol = "ssh-ng";
  };

  ssh-config = import (rootCfgPath + "/constants/ssh.nix") { };
in
{
  # ------------- networking -------------
  # apparently not having this enabled works until you enable docker?
  networking.networkmanager.enable = true;

  # ------------- nix config -------------
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };
  nix.settings.trusted-users = [
    "root"
    "cricro"
  ];

  # ------------- vscode-server -------------
  # blehh its always useful
  services.vscode-server.enable = true;

  # ------------- time -------------
  time.hardwareClockInLocalTime = true;
  i18n.defaultLocale = "en_US.UTF-8";

  # ------------- ssh -------------
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # ------------- main user -------------
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  users.users.cricro = {
    isNormalUser = true;
    description = "Christian";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "cdrom"
      "docker"
    ];
    packages = [ ];
    openssh.authorizedKeys.keys = ssh-config.owned-keys;
  };

  # ------------- remote building -------------
  nix.buildMachines = [
    (mkBuildMachine "100.64.0.1")
    (mkBuildMachine "100.64.0.8")
  ];
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  # ------------- privileged programs -------------
  services.locate.enable = true;
  environment.systemPackages = with pkgs; [
    kitty
    gparted
  ];

  # ------------- docker -------------
  # yes its a requirement for every host
  virtualisation.docker = {
    enable = true;
  };

  # ------------- system stuff -------------
  security.rtkit.enable = true;
}
