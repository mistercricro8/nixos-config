# Generators for home-manager home.file entries

{ config, ... }:

let
  utils = import ./utils.nix { };
in
rec {

  # Generate home.file entries for all files in a directory, preserving the directory structure.
  # relOriginDir (path): the current directory to read files recursively from, HAS to be a relative path due to pure evaluation mode
  # absOriginDir (path): the origin directory from which to create symlinks, HAS to be an absolute path due to symlink creation failing otherwise
  # prefix (str): accumulated prefix, should be "" when called externally
  # outDir (str): the output directory for the generated symlinks
  # returns: attrset usable directly in home.file
  mkRecursiveFiles =
    relOriginDir: absOriginDir: prefix: outDir:
    let
      items = builtins.attrNames (builtins.readDir relOriginDir);
    in
    builtins.listToAttrs (
      builtins.concatLists (
        map (
          name:
          let
            fullPath = "${relOriginDir}/${name}";
            relPath = if prefix == "" then name else "${prefix}/${name}";
          in
          if utils.isPathDir fullPath then
            builtins.attrValues (builtins.mapAttrs (name: value: { inherit name value; }) (mkRecursiveFiles fullPath absOriginDir relPath outDir))
          else
            [
              {
                name = "${outDir}/${relPath}";
                value = {
                  source = config.lib.file.mkOutOfStoreSymlink "${absOriginDir}/${relPath}";
                };
              }
            ]
        ) items
      )
    );

  # Generate home.file entries for all selected files in a directory.
  # originDir (path): the directory to read files from, HAS to be an absolute path due to how symlinks are created
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
