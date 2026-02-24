{
  lib,
  config,
  rootCfgPath,
  rootCfgPathAbs,
  configName ? null,
  ...
}:
let
  homeUtils = import ../home-utils.nix {
    inherit
      config
      lib
      configName
      rootCfgPath
      rootCfgPathAbs
      ;
  };
  mkConfigOption = homeUtils.mkConfigOption;
  applyConfig = homeUtils.applyConfig;
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
    in
    lib.mkIf cfg.enable {
      home.file = lib.mkMerge (
        lib.mapAttrsToList (name: configObj: applyConfig configObj name) cfg.configs
      );
    };
}
