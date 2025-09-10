# Generators for module import entries

{ config, ... }:

{
  # Generate a filtered list of imports from a folder of modules.
  # dir (path): the directory containing folders with imports
  # filter (list of str, optional): list of module names to include (without .nix extension)
  #                                 if null or empty, includes all modules
  # returns: list of import paths
  mkFolderImports =
    dir: filter:
    let
      allFiles = builtins.attrNames (builtins.readDir dir);
      nixFiles = builtins.filter (name: builtins.match ".*\\.nix$" name != null) allFiles;
      moduleNames = builtins.map (name: builtins.replaceStrings [ ".nix" ] [ "" ] name) nixFiles;
      filteredNames =
        if filter == null || filter == [ ] then
          moduleNames
        else
          builtins.filter (name: builtins.elem name filter) moduleNames;
    in
    builtins.map (name: dir + "/${name}.nix") filteredNames;
}
