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

  # temp / testing
  home.packages = with pkgs; [
    
  ];

  programs.vscode = {
    enable = true;
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
          chaitanyashahare.lazygit
          tomoki1207.pdf
          bbenoist.doxygen
          ms-vscode.cpptools
          eamodio.gitlens
          ms-vsliveshare.vsliveshare
          golang.go
          hoovercj.vscode-power-mode
        ])
        ++ [
          (pkgs.forVSCodeVersion pkgs.vscode.version).vscode-marketplace-release.github.copilot-chat
        ];
    };
  };

  xdg.desktopEntries = {
    VSCode = {
      name = "VSCode";
      genericName = "Wayland";
      exec = "code --ozone-platform=wayland";
      categories = [
        "TextEditor"
        "IDE"
      ];
      mimeType = [ "text/plain" ];
    };
    Postman = {
      name = "Postman";
      genericName = "Wayland";
      exec = "postman --ozone-platform=wayland";
      categories = [
        "Development"
        "Network"
      ];
      mimeType = [ "application/json" ];
    };
    Discord = {
      name = "Discord";
      genericName = "Wayland";
      exec = "discord --ozone-platform=wayland";
      categories = [
        "Network"
        "InstantMessaging"
      ];
      mimeType = [ ];
    };
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      codium = "codium --ozone-platform=wayland";
      code = "code --ozone-platform=wayland";
      nix-config = "cd ~/nixos-config && code . && exit";
      devflake-init = "bash ~/nixos-config/apps/devflake-init/init.sh";
      nix-cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      cls = "clear";
      docker = "podman";
      nix-rebuild = "bash ~/nixos-config/apps/nix-rebuild/rebuild.sh";
      cat = "bat";
    };
    shellInit = ''
      export NIXOS_OZONE_WL=1
      export JAVA_HOME="${pkgs.jdk}"
      export GOROOT="${pkgs.go}/lib/go"
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
      export NIXHOME="$HOME/nixos-config"
      direnv hook fish | source;
    '';
  };

  programs.starship.enable = true;

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
    settings = {
      editor = "code --wait";
    };
  };

  programs.git = {
    enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "code --wait";
    };
  };

  services.gnome-keyring.enable = true;

  wayland.windowManager.hyprland = {
    plugins = [
    ];
  };

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
