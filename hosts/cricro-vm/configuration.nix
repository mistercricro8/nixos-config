{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix    
    (fetchTarball {
      url = "https://github.com/nix-community/nixos-vscode-server/tarball/master";
      sha256 = "sha256:1rdn70jrg5mxmkkrpy2xk8lydmlc707sk0zb35426v1yxxka10by";
    })
  ];

  boot.binfmt.emulatedSystems = [
    "x86_64-linux"
  ];

  services.vscode-server.enable = true;

  boot.tmp.cleanOnBoot = true;
  boot.loader.grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

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

  nix.settings.trusted-users = [
    "nixremote"
  ];

  users.users.nixremote = {
    description = "Remote builds user";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      # cricro-vm
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnCUevyXnMK0jLKEEBQYSF5UoCiBQt7WZMbIo9y6/Nc root@instance-01"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPFlwEmkVmbWX2MTZtgQHQXFHqbIxc5dO4leGX1qFfI cricro@instance-01"
      # cricro-laptop-linux
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJyzkR8auawdWuIKq7Yrp0kFz/+nfvDKeli4lF+mgfQ root@cricro-laptop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQvMNCGvxpPmwxCBPiOf9o/B5tZymCRBg8Y7wgwsL57 cricro@cricro-laptop"
      # cricro-pc-windows
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICk894y0LXcl7iDLmaIkEa3SrW9NPoGHDVer+pjDen35 cricro@cricro-pc"
      # cricro-pc-linux
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCYtYcsQkILXoEtIUx0U/k5iSOxjmEWXZb4uQBiAZna root@cricro-pc"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWJOoS+mMH5g17O2uvmD33ZGFIz0fIhyx+8CIGUx8gP cricro@cricro-pc"
    ];
    homeMode = "500";
  };

  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

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
      jq
    ];
  };
}