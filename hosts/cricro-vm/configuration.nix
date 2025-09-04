{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix    
    (fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")
  ];

  services.vscode-server.enable = true;

  boot.tmp.cleanOnBoot = true;
  boot.loader.grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  virtualisation.docker = {
    enable = true;
  };

  networking.networkmanager.enable = true;

  zramSwap.enable = true;
  networking.hostName = "instance-01";
  networking.domain = "";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBnfJ4RuEoXZzImQxuGtB0aA047T/YaJ6r8QMPhyLrS+ cricro@nixos'' ];
  system.stateVersion = "23.11";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.cricro = {
        isNormalUser = true;
        description = "Christian";
        extraGroups = [
          "networkmanager"
          "wheel"
          "docker"
    ];
    packages = with pkgs; [
      micro
      git
    ];
  };
}