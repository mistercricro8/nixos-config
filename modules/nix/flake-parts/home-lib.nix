# Helper functions for home manager.
{ inputs, ... }:
{
  # Dictionary mapping configuration prefixes to their target directories relative to $HOME.
  config.flake.lib.hmConfigDirs = {
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

  # Create a configuration provider option.
  # lib        - the nixpkgs lib object
  # providers  - list of possible configuration providers
  config.flake.lib.mkProviderOption =
    { lib, providers }:
    lib.mkOption {
      type = lib.types.enum providers;
      default = builtins.head providers;
      description = "Configuration provider to use.";
    };

  # Create a full configuration option, containing an enable flag and a provider.
  # lib        - the nixpkgs lib object
  # providers  - list of possible configuration providers
  config.flake.lib.mkConfigOption =
    { lib, providers }:
    lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable this configuration.";
          };
          provider = inputs.self.lib.mkProviderOption { inherit lib providers; };
        };
      };
      default = { };
      description = "Configuration options.";
    };

  # Walk relOriginDir recursively, emitting one home.file entry per file.
  # relOriginDir  - store path used for builtins.readDir (eval-time traversal)
  # absOriginDir  - absolute runtime path for mkOutOfStoreSymlink targets
  # prefix        - accumulated relative sub-path (pass "" at the call site)
  # outDir        - home-relative target directory (e.g. ".config/hypr")
  config.flake.lib.mkRecursiveFiles =
    {
      lib,
      config,
      relOriginDir,
      absOriginDir,
      prefix,
      outDir,
    }:
    let
      items = builtins.attrNames (builtins.readDir relOriginDir);
      mkRecursiveFiles =
        relDir: pfx:
        inputs.self.lib.mkRecursiveFiles {
          inherit
            lib
            config
            absOriginDir
            outDir
            ;
          relOriginDir = relDir;
          prefix = pfx;
        };
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
              builtins.mapAttrs (n: v: {
                name = n;
                value = v;
              }) (mkRecursiveFiles fullPath relPath)
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

  # Produce home.file entries for a flat, explicitly-named list of files.
  # originDir  - absolute runtime path of the source directory
  # selection  - list of file names (or relative paths) under originDir
  # outDir     - home-relative target directory (use "." for $HOME)
  config.flake.lib.mkSelectedFiles =
    {
      config,
      originDir,
      selection,
      outDir,
    }:
    builtins.listToAttrs (
      map (fileName: {
        name = "${outDir}/${fileName}";
        value = {
          source = config.lib.file.mkOutOfStoreSymlink "${originDir}/${fileName}";
        };
      }) selection
    );

  # Apply a configuration provider to map host-specific configurations into home.file.
  # lib        - the nixpkgs lib object
  # config     - the system or home-manager config object
  # prefix     - prefix of the configuration to search for (e.g. "hyprland")
  # provider   - the selected provider strategy (e.g. "dir")
  config.flake.lib.applyConfigProvider =
    {
      lib,
      config,
      prefix,
      provider,
    }:
    let
      rootCfgPath = inputs.self;
      rootCfgPathAbs = config.systemConstants.rootCfgPathAbs;
      configName = config.systemConstants.configName;

      # True when the host-filter suffix matches the current configName.
      # suffix == ""        → matches all hosts
      # suffix == "-pc,l2" → matches only those configNames
      matchesConfig =
        pfx: suffix:
        if suffix == "" then
          true
        else if lib.hasPrefix "-" suffix then
          let
            configNames = lib.splitString "," (lib.removePrefix "-" suffix);
          in
          configName != "" && builtins.elem configName configNames
        else
          false;

      # Find the best-matching subdir of baseDir whose name starts with pfx.
      findConfigDir =
        pfx: baseDir:
        let
          allEntries = builtins.readDir baseDir;
          matchingDirs = lib.filterAttrs (
            name: type: type == "directory" && lib.hasPrefix pfx name
          ) allEntries;
          matched = lib.filter (name: matchesConfig pfx (lib.removePrefix pfx name)) (
            builtins.attrNames matchingDirs
          );
          sortedMatched = lib.sort (a: b: builtins.stringLength a > builtins.stringLength b) matched;
        in
        if builtins.length sortedMatched > 0 then baseDir + "/${builtins.head sortedMatched}" else null;
    in
    if provider == "dir" then
      let
        baseDir = rootCfgPath + "/config-dirs";
        baseDirAbs = rootCfgPathAbs + "/config-dirs";
        configDirName = findConfigDir prefix baseDir;
        targetDir = inputs.self.lib.hmConfigDirs.${prefix};
      in
      if configDirName != null then
        let
          dirName = lib.last (lib.splitString "/" (toString configDirName));
          relPath = baseDir + "/${dirName}";
          absPath = baseDirAbs + "/${dirName}";
        in
        inputs.self.lib.mkRecursiveFiles {
          inherit lib config;
          relOriginDir = relPath;
          absOriginDir = absPath;
          prefix = "";
          outDir = targetDir;
        }
      else
        { }
    else
      { };
}
