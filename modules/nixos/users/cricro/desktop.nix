{ inputs, ... }:
let
  user = "cricro";
in
{
  flake.modules.nixos."users/cricro/desktop" =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = (
        with inputs.self.factories;
        [
          (nixos."programs/browsers" { inherit user; })
          (nixos."programs/generic/gui-utils" { inherit user; })
          (nixos."programs/generic/media-utils" { inherit user; })
          (nixos."programs/mpv" { inherit user; })
          (nixos."programs/obs" { inherit user; })
          (nixos."development/vscode" { inherit user; })
          (nixos."development/zed" { inherit user; })
          (nixos."virtualisation/winapps" { inherit user; })
          (nixos."development/semester" { inherit user; })
          (nixos."desktop/hyprland" { inherit user; })
        ]
      );

      services.gnome.gnome-keyring.enable = true;
      programs.seahorse.enable = true;
      programs.ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";

      hjem.users.${user} = {
        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
          EDITOR = "zeditor -w";
          XDG_DATA_DIRS = "$XDG_DATA_DIRS:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}";
        };
      };
    };
}
