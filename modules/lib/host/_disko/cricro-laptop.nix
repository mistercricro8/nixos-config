{ ... }:
{
  # Old disko setup:
  # disko.devices = {
  #   disk = {
  #     main = {
  #       type = "disk";
  #       device = "/dev/nvme0n1";
  #       content = {
  #         type = "gpt";
  #         partitions = {
  #           ESP = {
  #             priority = 1;
  #             name = "ESP";
  #             start = "1M";
  #             end = "512M";
  #             type = "EF00";
  #             content = {
  #               type = "filesystem";
  #               format = "vfat";
  #               mountpoint = "/boot";
  #               mountOptions = [
  #                 "fmask=0077"
  #                 "dmask=0077"
  #               ];
  #             };
  #           };
  #           root = {
  #             size = "100%";
  #             content = {
  #               type = "btrfs";
  #               extraArgs = [ "-f" ];
  #               subvolumes = {
  #                 "root" = {
  #                   mountpoint = "/";
  #                   mountOptions = [
  #                     "compress=zstd"
  #                     "noatime"
  #                   ];
  #                 };
  #                 "home" = {
  #                   mountpoint = "/home";
  #                   mountOptions = [
  #                     "compress=zstd"
  #                     "noatime"
  #                   ];
  #                 };
  #                 "nix" = {
  #                   mountpoint = "/nix";
  #                   mountOptions = [
  #                     "compress=zstd"
  #                     "noatime"
  #                   ];
  #                 };
  #               };
  #             };
  #           };
  #         };
  #       };
  #     };
  #   };
  # };

  # Replica of deployed partition layout for cricro-laptop (ext4 root):
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
              end = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            swap = {
              size = "16G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            extra_efi = {
              size = "550M";
              type = "EF00";
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
