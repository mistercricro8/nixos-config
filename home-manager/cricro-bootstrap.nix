{
  pkgs,
  ...
}:
{
  home.username = "cricro";
  home.homeDirectory = "/home/cricro";
  home.stateVersion = "24.11";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.yazi.enable = true;
  programs.yazi.shellWrapperName = "y";
  services.gnome-keyring.enable = true;

  home.packages = with pkgs; [
    tree
    btop
    nix-output-monitor
    jq
    gnupg
    net-tools
    lm_sensors
    usbutils
  ];

  programs.git.enable = true;
  programs.micro.enable = true;

  programs.fish.enable = {
    enable = true;
    shellAliases = {
      nix-rebuild = "bash ~/nixos-config/apps/nix-rebuild/rebuild.sh";
    };
  };

  programs.home-manager.enable = true;
}
