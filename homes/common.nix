{ config, pkgs, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cricro";
  home.homeDirectory = "/home/cricro";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    vscodium
    swaynotificationcenter
    wireplumber
    hyprpolkitagent
    waybar
    hyprpaper
    rofi-wayland
    wl-clipboard
    cliphist
    nautilus
    hypridle
    hyprlock
    hyprshot
    hyprcursor
    nerd-fonts.caskaydia-mono
    catppuccin-gtk
    nwg-look
    brightnessctl
    neovim
    fzf
    htop
    tree
    devbox
    grim
    slurp
    swaybg
    swaylock
    brave
    micro
  ];

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
      libsForQt5.xdg-desktop-portal-kde
    ];
    config = {
      common = {
        default = ["gtk"];
      };
      Hyprland = {
        default = ["hyprland" "gtk"];
      };
      sway = {
        default = ["wlr" "gtk"];
      };
      KDE = {
        default = ["kde" "gtk"];
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
      nixroot="/etc/nixos"
      nixhome="$HOME/nixos-config"
      codiumdata="$HOME/.config/VSCodium"
      eval "$(direnv hook zsh)"
      nix-flake-init() { 
        $nixhome/programs/flake-init/combine "$@"
        echo '.direnv\n.envrc' >> .gitignore
        echo "use flake" >> .envrc
        direnv allow
      }
    '';

    shellAliases = {
      nix-root-config = "sudo codium --no-sandbox --user-data-dir $codiumdata $nixroot";
      nix-config = "cd $nixhome && codium .";
      nix-reload = "cd $nixhome && sudo nixos-rebuild switch --flake";
      nix-cleanup = "sudo nix-collect-garbage -d";
      cls = "clear";
      gitac = "git add . && git commit -m";
      gitp = "git push";
    };
    
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
  };

  programs.starship.enable = true;

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };

  programs.git = {
    enable = true;
    extraConfig.init.defaultBranch = "main";
  };

  programs.kitty.enable = true;

  services.gnome-keyring.enable = true;

  # wayland.windowManager.sway = {
  #   enable = true;
  #   wrapperFeatures.gtk = true;
  # };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  home.sessionVariables = {
    
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
