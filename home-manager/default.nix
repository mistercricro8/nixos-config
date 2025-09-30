# Default home manager configuration for all homes.
{
  pkgs,
  inputs,
  #rootCfgPath,
  ...
}:
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.username = "cricro";
  home.homeDirectory = "/home/cricro";
  home.stateVersion = "24.11";

  #sops = {
  #  age.keyFile = "/home/cricro/.config/sops/age/keys.txt";
  #  secrets = {
  #    kitty-rc-key = {
  #      sopsFile = rootCfgPath + "/secrets/local-keys.yaml";
  #      format = "yaml";
  #    };
  #  };
  #};

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

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
    settings = {
      editor = "code --wait";
    };
  };

  programs.git = {
    enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      # core.editor = "code --wait";
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
      code = "code --ozone-platform=wayland";
      ccode = "code --ozone-platform=wayland . && exit";
      nix-config = "cd ~/nixos-config && code . && exit";
      devflake-init = "bash ~/nixos-config/apps/devflake-init/init.sh";
      nix-cleanup = "nh clean all --ask";
      cls = "clear";
      docker-on = "sudo systemctl start docker.service docker.socket";
      docker-off = "sudo systemctl stop docker.service docker.socket";
      nix-rebuild = "bash ~/nixos-config/apps/nix-rebuild/rebuild.sh";
      cat = "bat";
      rcat = "bat -p";
      eza = "eza --icons=always";
      ls = "eza";
      ll = "eza -l";
      l = "eza -la";
    };
    functions = {
      cd = {
        body = ''
          echo try using z
          z $argv
        '';
      };
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
    shellInit = ''
      set -U __fish_greeting ""
    '';
  };
  catppuccin.fish.enable = true;

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    JAVA_HOME = "${pkgs.jdk}";
    GOROOT = "${pkgs.go}/lib/go";
    PATH = "$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin";
    EDITOR = "code --wait";
  };

  programs.home-manager.enable = true;
}
