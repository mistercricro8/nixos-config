{
  pkgs,
  customLib,
  hostName,
  ...
}:

let
  # mkBuildMachine = hostName: {
  #   hostName = hostName;
  #   sshUser = "nixremote";
  #   systems = [
  #     "x86_64-linux"
  #     "aarch64-linux"
  #   ];
  #   protocol = "ssh-ng";
  # };

  sshConfig = customLib.constants.sshConfig;
  # private = customLib.private;
in
{
  # ------------- gpg -------------
  #programs.gnupg = {
  #  agent.enable = true;
  #};

  # ------------- shared drive -------------
  # but but no sops? no.
  # environment.etc."secrets/smb-credentials.shared" = utils.makeEtcSecretFile ''
  #   username=${private.smbCreds.username}
  #   password=${private.smbCreds.password}
  # '';

  # environment.etc."secrets/auto.shared" = utils.makeEtcSecretFile ''
  #   /home/cricro/shared -fstype=cifs,credentials=/etc/secrets/smb-credentials.shared,uid=1000 ://cricro-vm/shared
  # '';

  # services.autofs = {
  #   enable = true;
  #   autoMaster = ''
  #     /- file:/etc/secrets/auto.shared
  #   '';
  # };

  # ------------- back to sopsing -------------
  sops.gnupg.home = "/home/cricro/.gnupg";

  # ------------- networking -------------
  # apparently not having this enabled works until you enable docker?
  networking.networkmanager.enable = true;

  # ------------- nix config -------------
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

  # ------------- of course -------------
  programs.nix-ld.enable = true;
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

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

  # ------------- remote building -------------
  # temporarily disabled as it's not quite what i expected it to be
  # nix.buildMachines = [
  #   (mkBuildMachine "100.64.0.4")
  #   (mkBuildMachine "100.64.0.8")
  # ];
  # nix.distributedBuilds = true;
  # nix.settings.builders-use-substitutes = true;

  # ------------- privileged programs -------------
  services.locate.enable = true;
  environment.systemPackages = with pkgs; [
    gparted
    docker-buildx
    cifs-utils
  ];

  # ------------- docker -------------
  # yes its a requirement for every host
  virtualisation.docker = {
    enable = true;
  };

  # ------------- system stuff -------------
  security.rtkit.enable = true;

  # ------------- networking -------------
  networking.hostName = hostName;
}
