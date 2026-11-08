{ inputs, ... }:
{
  flake.factories.nixos."programs/browsers" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs;
        [
          firefox
          ungoogled-chromium
          pywalfox-native
        ]
      );

      systemd.user.services.pywalfox-install = {
        description = "Install Pywalfox native messaging manifest";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.pywalfox-native}/bin/pywalfox install";
        };
      };
    };
}
