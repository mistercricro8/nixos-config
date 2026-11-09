{ inputs, ... }:
{
  flake.factories.nixos."development/tools" =
    {
      user ? "cricro",
    }:
    { pkgs, lib, ... }:
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        lib.flatten [
          (with pkgs; [
            android-tools
            kubectl
            playwright-driver.browsers
          ])
        ]
      );

      environment.sessionVariables = {
        PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      };
    };
}
