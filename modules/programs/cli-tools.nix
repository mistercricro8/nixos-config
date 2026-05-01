# CLI tools
{ inputs, ... }:
{
  flake.modules.homeManager.cli-tools =
    { pkgs, ... }:
    let
      stablePkgs = inputs.nixpkgs-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = inputs.self.lib.filterPlatformPackages pkgs (
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
          ripdrag
          resvg
          nmap
          krita
          smartmontools
          pulseaudio
          stablePkgs.yt-dlp
          p7zip
          ffmpeg
          tldr
          hyperfine
          nh
          playerctl
          gnupg
          net-tools
          lm_sensors
          usbutils
          iotop
        ]
      );

      programs.mpv = {
        enable = true;
        package = stablePkgs.mpv.override {
          scripts = with pkgs.mpvScripts; [
            mpris
          ];
        };
      };
      catppuccin.mpv.enable = true;

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
      };
      catppuccin.delta.enable = true;

      programs.zellij = {
        enable = true;
        settings = {
          show_startup_tips = false;
        };
      };
      catppuccin.zellij.enable = true;

      programs.fuzzel.enable = true;
      catppuccin.fuzzel.enable = true;

      programs.btop.enable = true;
      catppuccin.btop.enable = true;

      programs.fzf.enable = true;
      catppuccin.fzf.enable = true;
    };
}
