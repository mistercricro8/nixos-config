{ inputs, lib, ... }:
{
  config.flake.lib.dotfiles = {
    # Resolve the config-dirs directory name for a prefix + host configName.
    # Returns the directory name (not full path), preferring host-specific.
    resolveConfigDirName =
      { prefix, configName }:
      let
        configDirsStore = inputs.self + "/config-dirs";
        parentEntries = builtins.readDir configDirsStore;
        specificName = "${prefix}-${configName}";
      in
      if configName != "" && parentEntries ? ${specificName} then
        specificName
      else if parentEntries ? ${prefix} then
        prefix
      else
        null;

    # Recursively emit hjem file entries for a config-dirs entry (type = "path" or type = "flake").
    mkDotfileFiles =
      {
        prefix,
        configName,
        definitions ? inputs.self.lib.dotfiles.definitions,
      }:
      let
        rootCfgPathAbs = inputs.self.lib.constants.rootCfgPathAbs;
        targetDirConfig = definitions.${prefix} or null;
      in
      if targetDirConfig == null then
        { }
      else
        let
          entryType = targetDirConfig.type or "path";
          target = targetDirConfig.path;
          symlinkDir = targetDirConfig.symlinkDir or false;
        in
        if entryType == "path" then
          let
            dirName = inputs.self.lib.dotfiles.resolveConfigDirName { inherit prefix configName; };
          in
          if dirName == null then
            { }
          else
            let
              srcAbs = "${rootCfgPathAbs}/config-dirs/${dirName}";
              srcStore = inputs.self + "/config-dirs/${dirName}";
            in
            if symlinkDir then
              {
                "${target}" = {
                  source = srcAbs;
                  type = "symlink";
                  clobber = true;
                };
              }
            else
              let
                walkDir =
                  {
                    storeDir,
                    absDir,
                    relPrefix,
                    outPrefix,
                  }:
                  let
                    items = builtins.readDir storeDir;
                  in
                  lib.concatMapAttrs (
                    name: type:
                    let
                      relPath = if relPrefix == "" then name else "${relPrefix}/${name}";
                    in
                    if type == "directory" then
                      walkDir {
                        storeDir = "${storeDir}/${name}";
                        absDir = absDir;
                        relPrefix = relPath;
                        outPrefix = outPrefix;
                      }
                    else
                      {
                        "${outPrefix}/${relPath}" = {
                          source = "${absDir}/${relPath}";
                          type = "symlink";
                          clobber = true;
                        };
                      }
                  ) items;
              in
              walkDir {
                storeDir = srcStore;
                absDir = srcAbs;
                relPrefix = "";
                outPrefix = target;
              }
        else if entryType == "flake" then
          let
            inputName = targetDirConfig.inputName or prefix;
            inputStore = inputs.${inputName} or null;
            relSource = targetDirConfig.source or "";
            srcStore =
              if inputStore == null then
                null
              else if relSource == "" then
                inputStore
              else
                "${inputStore}/${relSource}";

            isDir =
              if srcStore == null || !(builtins.pathExists srcStore) then
                false
              else
                (builtins.readFileType srcStore) == "directory";
          in
          if srcStore == null || !(builtins.pathExists srcStore) then
            { }
          else if !isDir || symlinkDir then
            {
              "${target}" = {
                source = srcStore;
                type = "symlink";
                clobber = true;
              };
            }
          else
            let
              walkFlakeDir =
                { storeDir, relPrefix, outPrefix }:
                let
                  dirItems = builtins.readDir storeDir;
                in
                lib.concatMapAttrs (
                  name: type:
                  let
                    relPath = if relPrefix == "" then name else "${relPrefix}/${name}";
                  in
                  if type == "directory" then
                    walkFlakeDir {
                      storeDir = "${storeDir}/${name}";
                      relPrefix = relPath;
                      outPrefix = outPrefix;
                    }
                  else
                    {
                      "${outPrefix}/${relPath}" = {
                        source = "${storeDir}/${name}";
                        type = "symlink";
                        clobber = true;
                      };
                    }
                ) dirItems;
            in
            walkFlakeDir {
              storeDir = srcStore;
              relPrefix = "";
              outPrefix = target;
            }
        else
          { };
  };
}
