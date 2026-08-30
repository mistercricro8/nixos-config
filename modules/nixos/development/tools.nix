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
            android-studio
          ])
        ]
      );

      nixpkgs.config.android_sdk.accept_license = true;
    };
}
