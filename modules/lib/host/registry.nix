{ config, lib, ... }:
{
  # Host list declaration.
  config.flake.lib.host.registry = [
    {
      name = "cricro-pc";
      system = "x86_64-linux";
      deployHostname = "cricro-pc-l";
    }
    {
      name = "cricro-laptop";
      system = "x86_64-linux";
      deployHostname = "cricro-laptop";
    }
    {
      name = "cricro-l2";
      system = "x86_64-linux";
      deployHostname = "cricro-l2";
    }
    {
      name = "cricro-vm";
      system = "aarch64-linux";
      deployHostname = "cricro-vm";
    }
    {
      name = "bootstrap";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      diskoLayout = "cricro-l2"; # TODO: change here
    }
  ];

  # Map a system to its short arch suffix.
  config.flake.lib.host.archSuffix =
    system:
    if system == "x86_64-linux" then
      "x86"
    else if system == "aarch64-linux" then
      "aarch64"
    else
      throw "unsupported system: ${system}";

  # Expand the registry into one entry per concrete nixosConfiguration.
  # Entries with a single system map to themselves, entries with systems
  # produce one entry per system.
  config.flake.lib.host.expandHosts =
    hosts:
    lib.concatMap (
      entry:
      if entry ? systems then
        map (system: {
          inherit (entry) name;
          configName = "${entry.name}-${config.flake.lib.host.archSuffix system}";
          inherit system;
          deployHostname = entry.deployHostname or entry.name;
          diskoLayout = entry.diskoLayout or entry.name;
          sshUser = entry.sshUser or "nixremote";
        }) entry.systems
      else
        [
          (
            {
              sshUser = "nixremote";
            }
            // entry
            // {
              configName = entry.name;
              diskoLayout = entry.diskoLayout or entry.name;
            }
          )
        ]
    ) hosts;
}
