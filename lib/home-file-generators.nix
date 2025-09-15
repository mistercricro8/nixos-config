# Generators for home-manager home.file entries

{ config, ... }:

let
  utils = import ./utils.nix { };
in
rec {

  # Generate home.file entries for all files in a directory, preserving the directory structure.
  # dir (path): the current directory to read files recursively from
  # prefix (str): accumulated prefix, should be "" when called externally
  # originDir (path): the origin directory from which to create symlinks, has to be an absolute path
  # outDir (str): the output directory for the generated symlinks
  # returns: attrset usable directly in home.file
  mkRecursiveFiles =
    # TODO technically dir and originDir are the same path, check if removal doesnt affect pure evaluation mode
    dir: prefix: originDir: outDir:
    let
      items = builtins.attrNames (builtins.readDir dir);
    in
    builtins.listToAttrs (
      builtins.concatLists (
        map (
          name:
          let
            fullPath = "${dir}/${name}";
            relPath = if prefix == "" then name else "${prefix}/${name}";
          in
          if utils.isPathDir fullPath then
            builtins.attrValues (builtins.mapAttrs (name: value: { inherit name value; }) (mkRecursiveFiles fullPath relPath originDir outDir))
          else
            [
              {
                name = "${outDir}/${relPath}";
                value = {
                  source = config.lib.file.mkOutOfStoreSymlink "${originDir}/${relPath}";
                };
              }
            ]
        ) items
      )
    );

  # Generate home.file entries for all selected files in a directory.
  # originDir (path): the directory to read files from, (has to be an absolute path? TODO check)
  # selection (list of str): list of file names to include
  # outDir (str): the output directory for the generated symlinks
  # returns: attrset usable directly in home.file
  mkSelectedFiles =
    originDir: selection: outDir:
    builtins.listToAttrs (
      map (
        fileName:
        {
          name = "${outDir}/${fileName}";
          value = {
            source = config.lib.file.mkOutOfStoreSymlink "${originDir}/${fileName}";
          };
        }
      ) selection
    );

}
