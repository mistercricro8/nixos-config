{ inputs, ... }:
{
  flake.modules.nixos."hosts/cricro-sv2" =
    {
      pkgs,
      ...
    }:
    {
      systemConstants.configName = "sv2";

      imports =
        (with inputs.self.modules; [
          nixos."system/server"
          nixos."users/cricro/default"
          nixos."boot/minimal"
        ])
        ++ (with inputs.self.factories; [
          (nixos."secrets/ssh-keys" {
            keys = [ "id_ed25519" ];
          })
          (nixos."system/settings/networking" {
            netInterfaces = [ "enp30s0" ];
            wakeonlan = true;
            nftables = true;
          })
          (nixos."services/tailscale" {
            hostname = "cricro-sv2";
            hostType = "client";
          })
          (nixos."services/samba" {
            shares = {
              "files" = {
                path = "/home/LaEsquina/la-esquina-store/laesquina-management/files";
                guestOk = "no";
                writable = "yes";
                accessMode = "read-write";
                user = "LaEsquina";
                userData = {
                  homeMode = "0777";
                  hashedPassword = "$y$j9T$Fm/3aDe8MkmxKAX16PhK/0$sVt5FWmeQJbOkTFHQhT0DCqC3bti13ORbx/MiwDFXB2";
                };
              };
              "Archivos" = {
                path = "/home/LaEsquina/la-esquina-store/Archivos";
                guestOk = "no";
                writable = "yes";
                accessMode = "read-write";
                user = "LaEsquina";
              };
              "Medicina" = {
                path = "/home/LaEsquina/la-esquina-store/Medicina";
                guestOk = "no";
                writable = "yes";
                accessMode = "read-write";
                user = "LaEsquina";
              };
            };
          })
        ])
        ++ [
          (import _hardware/cricro-sv2.nix { inherit inputs; })
        ];

      # ============== Networking
      networking.hostName = "cricro-sv2";
      networking.firewall.trustedInterfaces = [
        "tailscale0"
      ];

      # ============== Time
      time.timeZone = "America/Lima";

      environment.systemPackages = with pkgs; [
        wakeonlan
      ];

      # ============== System
      system.stateVersion = "24.05";
    };
}
