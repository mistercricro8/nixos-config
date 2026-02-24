{
  lib,
  config,
  configName ? null,
  rootCfgPath,
  rootCfgPathAbs,
}:
rec {
  # A map of config dirs and their expected locations
  configDirs = {
    backgrounds = ".config/backgrounds";
    bottom = ".config/bottom";
    dms = ".config/DankMaterialShell";
    dms-gtk-3 = ".config/gtk-3.0";
    dms-gtk-4 = ".config/gtk-4.0";
    dms-qt5ct = ".config/qt5ct";
    dms-qt6ct = ".config/qt6ct";
    hyprland = ".config/hypr";
    kitty = ".config/kitty";
    rofi = ".config/rofi";
    swaync = ".config/swaync";
    vscode = ".config/Code/User";
    waybar = ".config/waybar";
    winapps = ".config/winapps";
    xsettingsd = ".config/xsettingsd";
    yazi = ".config/yazi";
    mimeapps = ".config";
    starship = ".config";
    zed = ".config/zed";
  };

  # Generate home.file entries for all files in a directory, preserving the directory structure.
  # relOriginDir (path): the current directory to read files recursively from, HAS to be a relative path due to pure evaluation mode
  # absOriginDir (path): the origin directory from which to create symlinks, HAS to be an absolute path due to symlink creation failing otherwise
  # prefix (str): accumulated prefix, should be "" when called externally
  # outDir (str): the output directory for the generated symlinks
  # returns: attrset for home.file
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
          if lib.pathIsDirectory fullPath then
            builtins.attrValues (
              builtins.mapAttrs (name: value: { inherit name value; }) (
                mkRecursiveFiles fullPath absOriginDir relPath outDir
              )
            )
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
  # returns: attrset for home.file
  mkSelectedFiles =
    originDir: selection: outDir:
    builtins.listToAttrs (
      map (fileName: {
        name = "${outDir}/${fileName}";
        value = {
          source = config.lib.file.mkOutOfStoreSymlink "${originDir}/${fileName}";
        };
      }) selection
    );

  # Check if a config directory with suffix matches the current configName
  # prefix (str): the prefix of the config directory
  # suffix (str): the suffix after the prefix ("", "-laptop", "-laptop,pc")
  # returns: bool indicating if this config should be used
  matchesConfig =
    prefix: suffix:
    if suffix == "" then
      true
    else if lib.hasPrefix "-" suffix then
      let
        configNames = lib.splitString "," (lib.removePrefix "-" suffix);
      in
      configName != null && builtins.elem configName configNames
    else
      false;

  # Find the appropriate config directory for a given prefix
  # prefix (str): the prefix to look for
  # baseDir (path): the base directory to search in
  # returns: path or null if no matching directory found
  findConfigDir =
    prefix: baseDir:
    let
      allEntries = builtins.readDir baseDir;
      matchingDirs = lib.filterAttrs (
        name: type: type == "directory" && lib.hasPrefix prefix name
      ) allEntries;
      matched = lib.filter (name: matchesConfig prefix (lib.removePrefix prefix name)) (
        builtins.attrNames matchingDirs
      );
    in
    if builtins.length matched > 0 then baseDir + "/${builtins.head matched}" else null;

  # Create a provider option with enum type
  # providers (list of str): list of allowed providers (first element is used as default)
  # returns: an option definition for lib.mkOption
  mkProviderOption =
    providers:
    lib.mkOption {
      type = lib.types.enum providers;
      default = builtins.head providers;
      description = "Configuration provider to use.";
    };

  # Create a configuration option with enable and provider fields
  # providers (list of str): list of allowed providers
  # returns: a submodule option definition
  mkConfigOption =
    providers:
    lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable this configuration.";
          };
          provider = mkProviderOption providers;
        };
      };
      default = { };
      description = "Configuration options.";
    };

  # Apply provider based configuration when provider is "dir"
  # prefix (str): the config prefix
  # provider (str): the provider to use
  # returns: attrset for home.file or empty attrset
  applyConfigProvider =
    prefix: provider:
    if provider == "dir" then
      let
        baseDir = rootCfgPath + "/home-manager/config-dirs";
        baseDirAbs = rootCfgPathAbs + "/home-manager/config-dirs";
        configDirName = findConfigDir prefix baseDir;
        targetDir = configDirs.${prefix};
      in
      if configDirName != null then
        let
          dirName = lib.last (lib.splitString "/" (toString configDirName));
          relPath = baseDir + "/${dirName}";
          absPath = baseDirAbs + "/${dirName}";
        in
        mkRecursiveFiles relPath absPath "" targetDir
      else
        { }
    else
      { };

  # Apply a configuration object after checking if it's enabled
  # configObj: an object with { enable, provider } fields
  # prefix: the config prefix
  # returns: attrset for home.file or empty attrset
  applyConfig =
    configObj: prefix: lib.mkIf configObj.enable (applyConfigProvider prefix configObj.provider);
}
