{ inputs, ... }:
{
  flake.modules.nixos."programs/flatpak" =
    {
      ...
    }:
    {
      imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
      services.flatpak.uninstallUnmanaged = true;
      services.flatpak.enable = true;
      dotfiles.profiles = [ "flatpak-overrides" ];
    };
}
