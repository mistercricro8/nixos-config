# Params:
#   shares - attrset of share configs (path, guestOk, writable, accessMode, user, userData)
#   workgroup - SMB workgroup name (default "WORKGROUP")
#   openFirewall - open samba ports in firewall (default true)
{ ... }:
{
  flake.factories.nixos."services/samba" =
    {
      shares ? { },
      workgroup ? "WORKGROUP",
      openFirewall ? true,
    }:
    {
      lib,
      ...
    }:
    let
      masks = {
        "read-only" = {
          createMask = "0744";
          directoryMask = "0755";
        };
        "read-write" = {
          createMask = "0766";
          directoryMask = "0777";
        };
      };

      mkUserConfig =
        username: userData:
        lib.mkMerge [
          {
            isNormalUser = true;
            homeMode = userData.homeMode;
          }
          (lib.mkIf (userData.hashedPassword != null) {
            hashedPassword = userData.hashedPassword;
          })
        ];

      userEntries = builtins.concatLists (
        map (
          name:
          let
            dir = shares.${name};
          in
          if dir ? userData && dir.userData != null then
            [
              {
                name = if (dir ? user && dir.user != null) then dir.user else name;
                value = mkUserConfig dir.user dir.userData;
              }
            ]
          else
            [ ]
        ) (builtins.attrNames shares)
      );
    in
    {
      services.samba = {
        enable = true;
        inherit openFirewall;
        nmbd.enable = false;
        settings = lib.mkMerge [
          {
            global = {
              "workgroup" = workgroup;
              "security" = "user";
              "access based share enum" = "yes";
            };
          }
          (lib.mapAttrs (
            _name: dirCfg:
            let
              chosenMasks = masks.${dirCfg.accessMode};
            in
            {
              "path" = dirCfg.path;
              "guest ok" = dirCfg.guestOk;
              "create mask" = chosenMasks.createMask;
              "browseable" = "yes";
              "writable" = dirCfg.writable;
              "directory mask" = chosenMasks.directoryMask;
              "force user" = lib.mkIf (dirCfg.user != null) dirCfg.user;
              "valid users" = lib.mkIf (dirCfg.user != null) dirCfg.user;
            }
          ) shares)
        ];
      };

      users.users = builtins.listToAttrs userEntries;

      services.samba-wsdd = {
        enable = true;
        inherit openFirewall;
      };
    };
}
