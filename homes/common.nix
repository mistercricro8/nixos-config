{ config
, pkgs
, inputs
, lib
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
  mkImports = dicts:
    builtins.concatLists (
      builtins.map
        (
          d:
          builtins.map (imp: ./${d.folder}/${imp}) d.imports
        )
        dicts
    );
  nixvim = inputs.nixvim.homeManagerModules.nixvim;
  vscode-extra-extensions = inputs.vscode-extensions.extensions.${pkgs.system};
in
{
  imports =
    mkImports import-dicts
    ++ [
      nixvim
    ];

  home.username = "cricro";
  home.homeDirectory = "/home/cricro";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    swaynotificationcenter
    wireplumber
    pavucontrol
    waybar
    rofi-wayland
    wl-clipboard
    cliphist
    nemo
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
    bottom
    lazygit
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    mutableExtensionsDir = false;
    profiles.default = {
      extensions = (with vscode-extra-extensions.vscode-marketplace; [
        ms-vscode.vscode-typescript-next
        detachhead.basedpyright
        catppuccin.catppuccin-vsc
        catppuccin.catppuccin-vsc-icons
      ])
      ++ (with pkgs.vscode-extensions; [
        github.copilot
        ms-vscode.cpptools
        jnoortheen.nix-ide
        visualstudioexptteam.vscodeintellicode
        bradlc.vscode-tailwindcss
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        ms-python.python
        ms-python.debugpy
        ms-python.black-formatter
      ]);
    };
  };

  home.sessionVariables.NIXOS_OZONE_WL = "1";

  xdg.desktopEntries = {
    VSCodium = {
      name = "VSCodium";
      genericName = "Wayland";
      exec = "codium --ozone-platform=wayland";
      categories = [ "TextEditor" "IDE" ];
      mimeType = [ "text/plain" ];
    };
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
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
      codium = "codium --ozone-platform=wayland";
      nix-config = "cd $nixhome && codium .";
      devflake-init = "bash $nixhome/apps/devflake-init/init.sh";
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
