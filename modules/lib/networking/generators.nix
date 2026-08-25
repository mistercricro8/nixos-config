{ ... }:
{
  config.flake.lib.networking = {
    mkIgnoreLocalDns =
      {
        name,
        interface,
        dns ? "1.1.1.1;8.8.8.8;",
      }:
      {
        ${name} = {
          connection = {
            id = name;
            type = "ethernet";
            inherit interface;
          };
          ipv4 = {
            method = "auto";
            inherit dns;
            ignore-auto-dns = true;
          };
          ipv6 = {
            method = "ignore";
          };
        };
      };
  };
}
