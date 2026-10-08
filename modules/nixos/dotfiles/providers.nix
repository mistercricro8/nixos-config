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
      pkgs,
      ...
    }:
    let
      allPrefixes = lib.unique (config.dotfiles.profiles ++ extra);
      configName = config.systemConstants.configName or "";
      userHome = config.users.users.${user}.home;
      userGroup = config.users.users.${user}.group;
      rootCfgPathAbs = config.systemConstants.rootCfgPathAbs or "${userHome}/nixos-config";
    in
    {
      systemd.tmpfiles.rules = [
        "d ${rootCfgPathAbs} 0755 ${user} ${userGroup} -"
      ];

      systemd.services."replicate-nixos-config-${user}" = {
        description = "Ensure nixos-config repository exists in ${user} home directory for hjem";
        wantedBy = [ "basic.target" ];
        before = [ "hjem-activate@${user}.service" ];
        after = [ "local-fs.target" ];
        path = [ pkgs.git ];
        script = ''
          if [ ! -f "${rootCfgPathAbs}/flake.nix" ]; then
            cp -r ${inputs.self}/. "${rootCfgPathAbs}/"
            chown -R ${user}:${userGroup} "${rootCfgPathAbs}"
            chmod -R u+rw "${rootCfgPathAbs}"
          fi
          if [ ! -d "${rootCfgPathAbs}/.git" ]; then
            git -C "${rootCfgPathAbs}" init -b main
            git -C "${rootCfgPathAbs}" remote add origin https://github.com/mistercricro8/nixos-config.git
            chown -R ${user}:${userGroup} "${rootCfgPathAbs}/.git"
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      hjem.users.${user}.files = lib.concatMapAttrs (
        prefix: _:
        inputs.self.lib.dotfiles.mkDotfileFiles {
          inherit prefix configName;
          definitions = config.dotfiles.definitions;
        }
      ) (lib.genAttrs allPrefixes (_: null));
    };
}
