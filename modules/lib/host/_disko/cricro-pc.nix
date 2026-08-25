# TODO: this will most definitely not work with how windows always
# prefers being installed first
{ ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0022"
                  "dmask=0022"
                ];
              };
            };
            reserved = {
              size = "16M";
            };
            windows = {
              size = "150G";
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };
      store = {
        type = "disk";
        device = "/dev/disk/by-uuid/ab8bbead-5ad6-40db-b940-589deb68344b";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/home/cricro/store";
        };
      };
      laesquina = {
        type = "disk";
        device = "/dev/disk/by-uuid/D624289724287C9D";
        content = {
          type = "filesystem";
          format = "ntfs3";
          mountpoint = "/home/LaEsquina/la-esquina-store";
        };
      };
    };
  };
}
