{ inputs, ... }:
{
  flake.factories.nixos."programs/generic/cli-utils" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs;
        [
          bubblewrap
          htop
          tree
          btop
          fd
          nix-output-monitor
          eza
          dust
          jq
          poppler
          ripgrep
          openssl
          ripdrag
          resvg
          p7zip
          tldr
          lazygit
          hyperfine
          nh
          playerctl
          gnupg
          nixd
          jujutsu
          fzf
          fuzzel
          starship
          atuin
          yazi
          bat
          micro
          gh
          git
          delta
          wineWow64Packages.stable
          zellij
        ]
      );

      dotfiles.profiles = [
        "scripts"
        "fish"
        "starship"
        "yazi"
        "micro"
        "bat"
        "atuin"
        "git"
      ];

      userConfig.${user}.fish.integrations = {
        dms-theme = {
          order = 10;
          text = ''
            if status is-interactive
              fish_config theme choose dms
            end
          '';
        };
        starship = ''
          if test "$TERM" != "dumb"
            ${pkgs.starship}/bin/starship init fish | source
          end
        '';
        zoxide = ''
          ${pkgs.zoxide}/bin/zoxide init fish | source
        '';
        fzf = {
          order = 40;
          text = ''
            ${pkgs.fzf}/bin/fzf --fish | source
          '';
        };
        atuin = ''
          ${pkgs.atuin}/bin/atuin init fish | source
        '';
        direnv = ''
          if not functions -q __direnv_export_eval
            ${pkgs.direnv}/bin/direnv hook fish | source
          end
        '';
      };
    };
}
