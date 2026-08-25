{ ... }:
{
  flake.modules.generic.user-options =
    { lib, config, ... }:
    let
      userSubmodule = lib.types.submodule {
        options.fish.integrations = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.coercedTo lib.types.lines (text: { inherit text; }) (
              lib.types.submodule {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Whether to enable this fish integration.";
                  };
                  text = lib.mkOption {
                    type = lib.types.lines;
                    description = "Fish script snippet to execute on shell startup.";
                  };
                  order = lib.mkOption {
                    type = lib.types.int;
                    default = 50;
                    description = "Order prefix for integration filename (e.g. 10 for theme, 50 for tools).";
                  };
                };
              }
            )
          );
          default = { };
          description = "Modular Fish shell integration snippets written to ~/.config/fish/integrations/ via hjem.";
        };
      };
    in
    {
      options.userConfig = lib.mkOption {
        type = lib.types.attrsOf userSubmodule;
        default = { };
        description = "Per-user configuration options.";
      };

      config.hjem.users = lib.mapAttrs (username: userCfg: {
        files = lib.concatMapAttrs (
          name: integration:
          if integration.enable then
            let
              orderPrefix =
                if integration.order < 10 then "0${toString integration.order}" else toString integration.order;
              fileName = "${orderPrefix}-${name}.fish";
            in
            {
              ".config/fish/integrations/${fileName}" = {
                text = integration.text;
              };
            }
          else
            { }
        ) userCfg.fish.integrations;
      }) config.userConfig;
    };
}
