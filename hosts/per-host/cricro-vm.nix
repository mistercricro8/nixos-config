{
  rootCfgPath,
  ...
}:

let
  nixos-modules = rootCfgPath + "/hosts/modules";
in
{
  imports = [
    ../default.nix
    (nixos-modules + "/boot/minimal.nix")
    (nixos-modules + "/builder/default.nix")
    (nixos-modules + "/hardware/cricro-vm.nix")
    (nixos-modules + "/overlays/default.nix")
  ];

  # ------------- boot -------------
  # repartitioning provisioned stuff scary
  # TODO update the terraform script to:
  # - umount /boot
  # - mount whatever /boot was using to /boot/efi
  # - mkdir /boot
  # thankfully grub is kind enough to accept this
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # ------------- time -------------
  time.timeZone = "America/Santiago";

  # ------------- system stuff -------------
  # uhh perhaps look out to keep this synced with the nix infect terraform script
  system.stateVersion = "23.05";

  # ------------- networking -------------
  # while just a passing thought, cricro-vm could receive a hostname and pretty much
  # generate a config ready for another instance
  networking.hostName = "instance-01";
}
