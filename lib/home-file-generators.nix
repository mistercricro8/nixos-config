{ config, ... }:

let
  utils = import ./utils.nix { };
in
rec {
  mkRecursiveEntries =
    dir: prefix: configDir:
    let
      items = builtins.attrNames (builtins.readDir dir);
    in
    builtins.concatLists (
      map (
        name:
        let
          fullPath = "${dir}/${name}";
          relPath = if prefix == "" then name else "${prefix}/${name}";
        in
        if utils.isPathDir fullPath then
          mkRecursiveEntries fullPath relPath configDir
        else
          [
            {
              name = ".config/${relPath}";
              value = {
                source = config.lib.file.mkOutOfStoreSymlink "${configDir}/config/${relPath}";
              };
            }
          ]
      ) items
    );

}
