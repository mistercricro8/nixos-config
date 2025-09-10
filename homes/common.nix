{
  rootCfgPath,
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
  import-generators = import (rootCfgPath + "/lib/import-generators.nix") { inherit config; };
  mkFolderImports = import-generators.mkFolderImports;
in
{
  imports = (mkFolderImports ./common/packages null) ++ [
    ./common/vscode-profiles.nix
  ];

  home.username = "cricro";
  home.homeDirectory = "/home/cricro";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    # kind of waiting for https://github.com/hyprwm/xdg-desktop-portal-hyprland/pull/308
    # rustdesk-flutter
    bottles
    unityhub
  ];

  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;
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
      code = "code --ozone-platform=wayland";
      ccode = "code --ozone-platform=wayland . && exit";
      nix-config = "cd ~/nixos-config && code . && exit";
      devflake-init = "bash ~/nixos-config/apps/devflake-init/init.sh";
      nix-cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      cls = "clear";
      docker-on = "sudo systemctl start docker.service docker.socket";
      docker-off = "sudo systemctl stop docker.service docker.socket";
      nix-rebuild = "bash ~/nixos-config/apps/nix-rebuild/rebuild.sh";
      cat = "bat";
      rcat = "bat -p";
      ls = "eza";
      ll = "eza -l";
      l = "eza -la";
    };
    shellInit = ''
      export NIXOS_OZONE_WL=1
      export JAVA_HOME="${pkgs.jdk}"
      export GOROOT="${pkgs.go}/lib/go"
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
      export NIXHOME="$HOME/nixos-config"
      function e
      	set tmp (mktemp -t "yazi-cwd.XXXXXX")
      	yazi $argv --cwd-file="$tmp"
      	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
      		builtin cd -- "$cwd"
      	end
      	rm -f -- "$tmp"
      end
      direnv hook fish | source
      zoxide init fish | source
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
