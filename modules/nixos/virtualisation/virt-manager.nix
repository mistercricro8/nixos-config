{ ... }:
{
  flake.modules.nixos."virtualisation/virt-manager" =
    { ... }:
    {
      programs.virt-manager.enable = true;
      users.groups.libvirtd.members = [ "cricro" ];
      virtualisation.libvirtd.enable = true;
      virtualisation.spiceUSBRedirection.enable = true;
    };
}
