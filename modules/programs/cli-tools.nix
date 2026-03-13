# CLI tools
{ inputs, ... }:
{
  flake.modules.homeManager.cli-tools =
    { pkgs, ... }:
    {
      home.packages = inputs.self.lib.filterPlatformPackages pkgs (
        with pkgs;
        [
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
          yt-dlp
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
        package = pkgs.mpv.override {
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
