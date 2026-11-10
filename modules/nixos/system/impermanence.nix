{ inputs, lib, ... }:
let
  baseSystemDirectories = [
    "/var/log"
    "/var/lib/nixos"
    "/var/lib/systemd/coredump"
    "/var/lib/sops-nix"
  ];

  baseSystemFiles = [
    "/etc/machine-id"
    "/etc/ssh/ssh_host_rsa_key"
    "/etc/ssh/ssh_host_rsa_key.pub"
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_ed25519_key.pub"
    "/etc/ssh/ssh_host_mldsa44_ed25519_key"
    "/etc/ssh/ssh_host_mldsa44_ed25519_key.pub"
  ];

  baseUserFiles = [
    ".ssh/known_hosts"
  ];
in
{
  flake.factories.nixos."system/impermanence" =
    {
      device ? "/dev/disk/by-partlabel/disk-main-root",
      persistPath ? "/persist",
      wipeRoot ? true,
      wipeHome ? true,
      retentionDays ? 30,
      directories ? [ ],
      files ? [ ],
      user ? "cricro",
      userDirectories ? [ ],
      userFiles ? [ ],
      users ? { },
    }:
    {
      utils,
      ...
    }:
    let
      enableInitrdWipe = wipeRoot || wipeHome;
      wipeScript = ''
        mkdir -p /btrfs_tmp
        mount ${device} /btrfs_tmp
        trap 'umount -l /btrfs_tmp 2>/dev/null || true' EXIT

        ${lib.optionalString wipeRoot ''
          if [ -e /btrfs_tmp/root ]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
            if [ -e "/btrfs_tmp/old_roots/$timestamp" ]; then
              timestamp="$timestamp-$(date +%s)"
            fi
            mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
          fi
          btrfs subvolume create /btrfs_tmp/root
        ''}

        ${lib.optionalString wipeHome ''
          if [ -e /btrfs_tmp/home ]; then
            mkdir -p /btrfs_tmp/old_homes
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/home)" "+%Y-%m-%-d_%H:%M:%S")
            if [ -e "/btrfs_tmp/old_homes/$timestamp" ]; then
              timestamp="$timestamp-$(date +%s)"
            fi
            mv /btrfs_tmp/home "/btrfs_tmp/old_homes/$timestamp"
          fi
          btrfs subvolume create /btrfs_tmp/home
        ''}

        find /btrfs_tmp/old_roots /btrfs_tmp/old_homes -mindepth 1 -maxdepth 1 -mtime +${toString retentionDays} 2>/dev/null | while read -r old_subvol; do
          [ -n "$old_subvol" ] && btrfs subvolume delete --recursive "$old_subvol"
        done || true
      '';

      primaryUserConfig =
        if user != null then
          {
            ${user} = {
              directories = userDirectories;
              files = lib.unique (baseUserFiles ++ userFiles);
            };
          }
        else
          { };
    in
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      boot.initrd.systemd.services.wipe-root = lib.mkIf enableInitrdWipe {
        unitConfig.DefaultDependencies = false;
        serviceConfig.Type = "oneshot";
        wantedBy = [ "initrd.target" ];
        before = [ "sysroot.mount" ];
        requires = [ "${utils.escapeSystemdPath device}.device" ];
        after = [
          "${utils.escapeSystemdPath device}.device"
          "local-fs-pre.target"
        ];
        script = wipeScript;
      };

      environment.persistence.${persistPath} = {
        hideMounts = true;

        directories = lib.unique (baseSystemDirectories ++ directories);
        files = lib.unique (baseSystemFiles ++ files);

        users = lib.recursiveUpdate primaryUserConfig users;
      };

      fileSystems = lib.mkMerge [
        { ${persistPath}.neededForBoot = true; }
        (lib.mkIf wipeHome { "/home".neededForBoot = true; })
      ];
    };
}
