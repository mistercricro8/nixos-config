# Default home manager configuration for all homes.
{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.dms.homeModules.dankMaterialShell.default
  ];

  home.username = "cricro";
  home.homeDirectory = "/home/cricro";
  home.stateVersion = "24.11";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Should be okay to just install adw-gtk3 as part of enabling dms
  # gtk = {
  #   enable = true;
  #   theme = {
  #     name = "awd-gtk3";
  #     package = pkgs.adw-gtk3;
  #   };
  # };

  catppuccin = {
    flavor = "mocha";
    accent = "yellow";
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
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
    settings = {
      init.defaultBranch = "main";
    };
  };

  programs.micro.enable = true;
  catppuccin.micro = {
    enable = true;
    transparent = true;
  };

  programs.yazi.enable = true;
  catppuccin.yazi.enable = true;

  programs.bat.enable = true;
  catppuccin.bat.enable = true;

  services.gnome-keyring.enable = true;

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
  };
  catppuccin.atuin.enable = true;

  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "done";
        src = pkgs.fishPlugins.done;
      }
    ];
    shellAliases = {
      ccode = "code . && exit";
      zzed = "zeditor . && exit";
      nix-config = "cd ~/nixos-config && zeditor . && exit";
      devflake-init = "bash ~/nixos-config/apps/devflake-init/init.sh";
      nix-cleanup = "nh clean all --ask";
      cls = "clear";
      nix-rebuild = "bash ~/nixos-config/apps/nix-rebuild/rebuild.sh";
      cat = "bat";
      rcat = "bat -p";
      eza = "eza --icons=always";
      ls = "eza";
      ll = "eza -l";
      l = "eza -la";
    };
    functions = {
      e = {
        body = ''
          set tmp (mktemp -t "yazi-cwd.XXXXXX")
          yazi $argv --cwd-file="$tmp"
          if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
          end
          rm -f -- "$tmp"
        '';
      };
    };
    shellInit = "";
  };
  catppuccin.fish.enable = true;

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    JAVA_HOME = "${pkgs.jdk}";
    GOROOT = "${pkgs.go}/lib/go";
    PATH = "$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin";
    EDITOR = "zeditor -w";
  };

  programs.home-manager.enable = true;
}
