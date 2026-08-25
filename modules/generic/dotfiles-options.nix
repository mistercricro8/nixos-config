{ inputs, ... }:
{
  flake.modules.generic.dotfiles-options =
    { lib, ... }:
    let
      configDirType = lib.types.submodule {
        options = {
          type = lib.mkOption {
            type = lib.types.enum [
              "path"
              "flake"
            ];
            default = "path";
            description = "Whether this dotfile config dir is from a local path or remote flake input.";
          };
          path = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Target path in $HOME where dotfile files should be symlinked.";
          };
          source = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Subpath inside local config-dirs or remote flake input.";
          };
          symlinkDir = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to symlink the entire directory as a single symlink.";
          };
          input = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Flake input dict when type = 'flake'.";
          };
          inputName = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Explicit input name for flake-file when type = 'flake'.";
          };
        };
      };
    in
    {
      options.dotfiles = {
        profiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Dotfile profile names this fragment needs symlinked into $HOME via the dotfiles provider.";
        };

        definitions = lib.mkOption {
          type = lib.types.attrsOf configDirType;
          default = inputs.self.lib.dotfiles.definitions;
          description = "Mapping of dotfile profile names to their source definitions (path or flake). Can be overridden per host.";
        };
      };
    };
}
