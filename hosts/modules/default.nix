{
  pkgs,
  ...
}:

{
  # ------------- networking -------------
  # apparently not having this enabled works until you enable docker?
  networking.networkmanager.enable = true;

  # ------------- flakes -------------
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  # ------------- ssh -------------
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
  # for remote building, nix uses the root user, so the keys under /root/.ssh
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

  # ------------- remote building -------------
  nix.buildMachines = [
    {
      hostName = "100.64.0.1";
      sshUser = "nixremote";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      protocol = "ssh-ng";
    }
  ];
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  # ------------- privileged programs -------------
  services.locate.enable = true;

  # ------------- docker -------------
  # yes its a requirement for every host 
    virtualisation.docker = {
    enable = true;
  };

  # ------------- system stuff -------------
  security.rtkit.enable = true;
}
