{
  config,
  pkgs,
  ...
}:
let
  import-dicts = [
    {
      folder = "common/packages";
      imports = builtins.attrNames (builtins.readDir ./common/packages);
    }
  ];
  mkImports =
    dicts:
    builtins.concatLists (builtins.map (d: builtins.map (imp: ./${d.folder}/${imp}) d.imports) dicts);
in
{
  imports = mkImports import-dicts ++ [
  ];

  home.username = "cricro";
  home.homeDirectory = "/home/cricro";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    libreoffice-qt
    swaynotificationcenter
    pavucontrol
    waybar
    discord
    rofi-wayland
    wl-clipboard
    cliphist
    nemo
    nerd-fonts.caskaydia-mono
    nerd-fonts.jetbrains-mono
    catppuccin-gtk
    nwg-look
    brightnessctl
    catppuccin-cursors.mochaYellow
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
    jq
    nwg-displays
    lm_sensors
    ruff
    clang-tools
    devenv
    nixfmt-rfc-style
    nixd
    wine64
    tldr
    jdk24
  ];

  programs.vscode = {
    enable = true;
    # package = pkgs.vscodium;
    mutableExtensionsDir = false;
    profiles.default = {
      extensions =
        (with pkgs.vscode-marketplace; [
          ms-vscode.vscode-typescript-next
          catppuccin.catppuccin-vsc
          catppuccin.catppuccin-vsc-icons
          prisma.prisma
          ms-azuretools.vscode-docker
          visualstudioexptteam.vscodeintellicode
          github.copilot
          llvm-vs-code-extensions.vscode-clangd
          jnoortheen.nix-ide
          bradlc.vscode-tailwindcss
          dbaeumer.vscode-eslint
          esbenp.prettier-vscode
          ms-python.python
          ms-python.debugpy
          charliermarsh.ruff
          detachhead.basedpyright
          vscjava.vscode-java-debug
          cweijan.vscode-mysql-client2
          vscjava.vscode-java-pack
          redhat.java
          vscjava.vscode-java-debug
          vscjava.vscode-java-dependency
          vscjava.vscode-maven
          github.copilot-chat
          # ms-python.vscode-pylance
          # ms-python.black-formatter
        ])
        ++ [
          # (pkgs.forVSCodeVersion "1.101.03933").vscode-marketplace-release.github.copilot-chat
        ];
    };
  };

  xdg.desktopEntries = {
    VSCodium = {
      name = "VSCodium";
      genericName = "Wayland";
      exec = "codium --ozone-platform=wayland";
      categories = [
        "TextEditor"
        "IDE"
      ];
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
      export NIXOS_OZONE_WL=1
      export JAVA_HOME="${pkgs.jdk}"
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
      nixhome="$HOME/nixos-config"
      eval "$(direnv hook zsh)"
      bindkey '^H' backward-kill-word
      bindkey '^[[3;5~' kill-word
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
    '';

    shellAliases = {
      codium = "codium --ozone-platform=wayland";
      code = "code --ozone-platform=wayland";
      nix-config = "cd $nixhome && code .";
      devflake-init = "bash $nixhome/apps/devflake-init/init.sh";
      nix-reload = "cd $nixhome && sudo nixos-rebuild switch --flake";
      nix-cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      ss = "ssh ubuntu@dev.mistercricro8.me";
      cls = "clear";
      docker = "podman";
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
