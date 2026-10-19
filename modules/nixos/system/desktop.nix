{ inputs, ... }:
{
  flake.modules.nixos."system/desktop" =
    {
      ...
    }:
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

      dotfiles.profiles = [
        "face"
      ];

      programs.dconf.enable = true;

      programs.xfconf.enable = true;
      services.gvfs.enable = true;
      services.tumbler.enable = true;
    };
}
