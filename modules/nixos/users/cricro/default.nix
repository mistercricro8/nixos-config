{ inputs, ... }:
let
  user = "cricro";
in
{
  flake.modules.nixos."users/cricro/default" =
    {
      config,
      lib,
      ...
    }:
    {
      imports = (
        with inputs.self.factories;
        [
          (nixos."programs/generic/cli-utils" { inherit user; })
          (nixos."development/tools" { inherit user; })
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

      hjem.users.${user} = {
        packages = [ ];

        environment.sessionVariables = {
          PATH = "$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin";
          EDITOR = lib.mkDefault "micro";
          KUBECONFIG = "/home/${user}/.kube/config";
        };
      };
    };
}
