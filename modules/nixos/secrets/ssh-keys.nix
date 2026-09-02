{ inputs, ... }:
{
  flake.modules.nixos."secrets/ssh-keys" =
    { config, lib, ... }:
    let
      hostName = config.networking.hostName;
      supportedHosts = [
        "cricro-pc"
        "cricro-laptop"
        "cricro-vm"
        "cricro-l2"
      ];
      sshSecretFile = inputs.self + "/secrets/ssh.yaml";
    in
    lib.mkIf (builtins.elem hostName supportedHosts) {
      sops.secrets."ssh-id_ed25519" = {
        sopsFile = sshSecretFile;
        key = "hosts/${hostName}/id_ed25519";
        path = "/home/cricro/.ssh/id_ed25519";
        owner = "cricro";
        group = "users";
        mode = "0600";
      };

      sops.secrets."ssh-id_ed25519_pub" = {
        sopsFile = sshSecretFile;
        key = "hosts/${hostName}/id_ed25519_pub";
        path = "/home/cricro/.ssh/id_ed25519.pub";
        owner = "cricro";
        group = "users";
        mode = "0644";
      };

      sops.secrets."ssh-gh_mistercricro8" = lib.mkIf (hostName == "cricro-pc") {
        sopsFile = sshSecretFile;
        key = "hosts/${hostName}/gh_mistercricro8";
        path = "/home/cricro/.ssh/gh_mistercricro8";
        owner = "cricro";
        group = "users";
        mode = "0600";
      };

      sops.secrets."ssh-gh_mistercricro8_pub" = lib.mkIf (hostName == "cricro-pc") {
        sopsFile = sshSecretFile;
        key = "hosts/${hostName}/gh_mistercricro8_pub";
        path = "/home/cricro/.ssh/gh_mistercricro8.pub";
        owner = "cricro";
        group = "users";
        mode = "0644";
      };
    };
}
