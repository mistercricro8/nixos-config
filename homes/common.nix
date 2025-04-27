{ config, pkgs, inputs, ... }:

let
  vscode-extra-extensions = inputs.vscode-extensions.extensions.${pkgs.system};
  nixvim = inputs.nixvim.packages.${pkgs.system}.default;
in
{
  home.username = "cricro";
  home.homeDirectory = "/home/cricro";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions =
      (with vscode-extra-extensions.vscode-marketplace; [
        ms-vscode.vscode-typescript-next
        detachhead.basedpyright
      ]) ++ (with pkgs.vscode-extensions; [
        # jnoortheen.nix-ide
        # arrterian.nix-env-selector
        github.copilot
        ms-vscode.cpptools
        visualstudioexptteam.vscodeintellicode
        bradlc.vscode-tailwindcss
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        ms-python.python
        ms-python.debugpy
        ms-python.black-formatter
      ]);
    })
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
    nixvim
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

    initContent = ''
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
      reload-wg = "sudo ifconfig wg0 down && sudo ifconfig wg0 up";
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
