{ inputs, ... }:
{
  flake.factories.nixos."dotfiles/providers" =
    {
      user ? "cricro",
      extra ? [ ],
    }:
    {
      config,
      lib,
      ...
    }:
    let
      allPrefixes = lib.unique (config.dotfiles.profiles ++ extra);
      configName = config.systemConstants.configName or "";
    in
    {
      hjem.users.${user}.files = lib.concatMapAttrs (
        prefix: _:
        inputs.self.lib.dotfiles.mkDotfileFiles {
          inherit prefix configName;
          definitions = config.dotfiles.definitions;
        }
      ) (lib.genAttrs allPrefixes (_: null));
    };
}
