# Zed.
{ inputs, ... }:
{
  flake.modules.homeManager.zed =
    { pkgs, ... }:
    {
      home.packages = inputs.self.lib.filterPlatformPackages pkgs (
        with pkgs;
        [
          ruff
          clang-tools
          jdk
          lazygit
          go
          shellcheck
          shfmt
          nixd
          typst
          nixfmt
          matlab-language-server
        ]
      );

      programs.zed-editor.enable = true;
    };
}
