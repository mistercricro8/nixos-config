# Module for handling automatic symlinking of dotfiles
{ inputs, ... }:
{
  flake.modules.homeManager.dotfiles =
    { lib, config, ... }:
    let
      slib = inputs.self.lib;
      mkConfigOption = providers: slib.mkConfigOption { inherit lib providers; };
      applyConfigProvider =
        prefix: provider:
        slib.applyConfigProvider {
          inherit
            lib
            config
            prefix
            provider
            ;
        };
    in
    {
      options.sDotfiles = with lib; {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable the simplified dotfiles configuration module.";
        };

        configs = mkOption {
          type = types.submodule {
            options = {
              backgrounds = mkConfigOption [ "dir" ];
              bottom = mkConfigOption [ "dir" ];
              kitty = mkConfigOption [ "dir" ];
              rofi = mkConfigOption [ "dir" ];
              swaync = mkConfigOption [ "dir" ];
              vscode = mkConfigOption [ "dir" ];
              zed = mkConfigOption [ "dir" ];
              winapps = mkConfigOption [ "dir" ];
              xsettingsd = mkConfigOption [ "dir" ];
              yazi = mkConfigOption [ "dir" ];
              mimeapps = mkConfigOption [ "dir" ];
              starship = mkConfigOption [ "dir" ];
            };
          };
          default = { };
          description = "Individual dotfile configurations.";
        };
      };

      config =
        let
          cfg = config.sDotfiles;
          applyConfig =
            configObj: prefix: lib.mkIf configObj.enable (applyConfigProvider prefix configObj.provider);
        in
        lib.mkIf cfg.enable {
          home.file = lib.mkMerge (
            lib.mapAttrsToList (name: configObj: applyConfig configObj name) cfg.configs
          );
        };
    };
}
