{ config
, pkgs
, inputs
, ...
}:
let
  import-dicts = [
    {
      folder = "common/nixvim";
      imports = builtins.attrNames (builtins.readDir ./common/nixvim);
    }
    {
      folder = "common/packages";
      imports = builtins.attrNames (builtins.readDir ./common/packages);
    }
  ];
  makeImports = dicts:
    builtins.concatLists (
      builtins.map
        (
          d:
          builtins.map (imp: ./${d.folder}/${imp}) d.imports
        )
        dicts
    );
  nixvim = inputs.nixvim.homeManagerModules.nixvim;
in
{
  imports =
    makeImports import-dicts
    ++ [
      nixvim
    ];

  home.username = "cricro";
  home.homeDirectory = "/home/cricro";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = [ ];
    })
    swaynotificationcenter
    wireplumber
    pavucontrol
    waybar
    rofi-wayland
    wl-clipboard
    cliphist
    nautilus
    nerd-fonts.caskaydia-mono
    catppuccin-gtk
    nwg-look
    brightnessctl
    htop
    tree
    grim
    slurp
    swaybg
    swaylock
    (brave.override {
      commandLineArgs = [
        "--enable-features=VaapiVideoDecodeLinuxGL"
        "--use-gl=angle"
        "--use-angle=gl"
        "--ozone-platform=wayland"
        "--password-store=gnome"
      ];
    })
    micro
    lorien
    rnote
    jflap
    zed-editor
    fd
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
        default = [ "gtk" ];
      };
      Hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
      };
      sway = {
        default = [
          "wlr"
          "gtk"
        ];
      };
      KDE = {
        default = [
          "kde"
          "gtk"
        ];
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
      nixhome="$HOME/nixos-config"
      eval "$(direnv hook zsh)"
    '';

    shellAliases = {
      devflake-init = "$nixhome/apps/devflake-init/init.sh";
      nix-config = "cd $nixhome && nvim .";
      nix-reload = "cd $nixhome && sudo nixos-rebuild switch --flake";
      nix-cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      cls = "clear";
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

  # programs.kitty.enable = true;

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
  home.sessionVariables = { };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
