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

  # Replica of deployed partition layout for cricro-l2:
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            win_efi = {
              size = "100M";
              type = "EF00";
            };
            win_reserved = {
              size = "16M";
            };
            windows = {
              size = "463.6G";
            };
            win_recovery = {
              size = "522M";
            };
            root = {
              size = "467.3G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            ESP = {
              size = "100%";
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
          };
        };
      };
    };
  };
}
