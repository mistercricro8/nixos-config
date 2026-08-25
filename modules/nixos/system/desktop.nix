{ inputs, ... }:
{
  flake.modules.nixos."system/desktop" =
    {
      pkgs,
      ...
    }:
    let
      playwright-mcp-pkg = inputs.playwright-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      imports = (
        with inputs.self.modules;
        [
          nixos."system/default"
          nixos."desktop/hyprland"
          nixos."desktop/kde"
          nixos."system/settings/peripherals"
        ]
      );

      programs.dconf.enable = true;

      programs.xfconf.enable = true;
      services.gvfs.enable = true;
      services.tumbler.enable = true;

      systemd.user.services.playwright-mcp = {
        enable = true;
        description = "Playwright MCP Server running over SSE";

        after = [ "network.target" ];
        wantedBy = [ "default.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${playwright-mcp-pkg}/bin/playwright-mcp-sse";
          Restart = "always";
          RestartSec = "3";
        };
      };
    };
}
