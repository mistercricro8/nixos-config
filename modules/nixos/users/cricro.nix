{ inputs, ... }:
let
  user = "cricro";
in
{
  flake.modules.nixos."users/cricro" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = (
        with inputs.self.factories;
        [
          (nixos."programs/browsers" { inherit user; })
          (nixos."programs/generic/cli-utils" { inherit user; })
          (nixos."programs/generic/gui-utils" { inherit user; })
          (nixos."programs/generic/media-utils" { inherit user; })
          (nixos."programs/mpv" { inherit user; })
          (nixos."programs/obs" { inherit user; })
          (nixos."development/vscode" { inherit user; })
          (nixos."development/tools" { inherit user; })
          (nixos."development/zed" { inherit user; })
          (nixos."virtualisation/winapps" { inherit user; })
          (nixos."development/semester" { inherit user; })
          (nixos."desktop/hyprland" { inherit user; })
          (nixos."dotfiles/providers" { inherit user; })
        ]
      );

      users.users.cricro = {
        isNormalUser = true;
        description = "";
        extraGroups = [
          "networkmanager"
          "wheel"
          "dialout"
          "cdrom"
          "docker"
          "uinput"
        ];
        packages = [ ];
        initialHashedPassword = "$y$j9T$RazGk8052EF4mQC2UYWA5/$KBvZpKyhxrZoFzM13c7y6i./096sDAQZ1FO3qL.ecX.";
        openssh.authorizedKeys.keys = config.systemConstants.sshConfig.ownKeys;
      };

      programs.fish.enable = true;
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      programs.zoxide.enable = true;
      services.gnome.gnome-keyring.enable = true;
      programs.seahorse.enable = true;
      programs.ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";

      hjem.users.${user} = {
        packages = [ ];

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
          PATH = "$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin";
          EDITOR = "zeditor -w";
          KUBECONFIG = "/home/${user}/.kube/config";
          XDG_DATA_DIRS = "$XDG_DATA_DIRS:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}";
        };
      };
    };
}
