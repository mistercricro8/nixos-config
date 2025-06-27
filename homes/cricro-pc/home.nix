{
  pkgs,
  config,
  inputs,
  ...
}:

let
  split-monitor-workspaces-hypr =
    inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces;
  storeDir = "${config.home.homeDirectory}/store";
  thisHomeDir = "${config.home.homeDirectory}/nixos-config/homes/cricro-pc";
  pathIsDir = path: builtins.pathExists (toString path + "/.");
  mkRecursiveEntries =
    dir: prefix:
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
        if pathIsDir fullPath then
          mkRecursiveEntries fullPath relPath
        else
          [
            {
              name = ".config/${relPath}";
              value = {
                source = config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/config/${relPath}";
              };
            }
          ]
      ) items
    );
  storeDirs = [
    "unsa"
    "repos"
    "tiny-projects"
    "projects"
    "important"
  ];
  mkStoreEntry = name: {
    name = "${name}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${storeDir}/${name}";
    };
  };

in
{
  imports = [
    ../common.nix
  ];

  home.packages = with pkgs; [
    playerctl
    audio-recorder
    split-monitor-workspaces-hypr
    # davinci-resolve
  ];

  programs.mpv = {
    enable = true;
    package = pkgs.mpv-unwrapped.wrapper {
      mpv = pkgs.mpv-unwrapped;
      scripts = with pkgs.mpvScripts; [
        mpris
      ];
    };
  };

  home.file = (
    builtins.listToAttrs (mkRecursiveEntries ./config "")
    // builtins.listToAttrs (map mkStoreEntry storeDirs)
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
      ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk24}";
      ".hypr/plugins/libsplit-monitor-workspaces.so".source =
        config.lib.file.mkOutOfStoreSymlink "${split-monitor-workspaces-hypr}/lib/libsplit-monitor-workspaces.so";
    }
  );
}
