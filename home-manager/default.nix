# Default home manager configuration for all homes.
{
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

  home.username = "cricro";
  home.homeDirectory = "/home/cricro";
  home.stateVersion = "24.11";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.starship.enable = true;

  programs.mpv = {
    enable = true;
    package = pkgs.mpv-unwrapped.wrapper {
      mpv = pkgs.mpv-unwrapped;
      scripts = with pkgs.mpvScripts; [
        mpris
      ];
    };
  };

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

  programs.fish = {
    enable = true;
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
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    JAVA_HOME = "${pkgs.jdk}";
    GOROOT = "${pkgs.go}/lib/go";
    PATH = "$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin";
  };

  programs.home-manager.enable = true;
}
