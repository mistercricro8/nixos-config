{ inputs, ... }:
{
  flake.factories.nixos."development/tools" =
    {
      user ? "cricro",
    }:
    { pkgs, lib, ... }:
    let
      omp = inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.omp;
    in
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        lib.flatten [
          (with pkgs; [
            opencode
            github-copilot-cli
            antigravity-cli
            android-tools
            kubectl
            android-studio
          ])
          [ omp ]
        ]
      );

      nixpkgs.config.android_sdk.accept_license = true;

      dotfiles.profiles = [
        "opencode"
        "gemini"
        "copilot"
      ];

      userConfig.${user}.fish.integrations = {
        omp = ''
          omp completions fish > $HOME/.config/fish/completions/omp.fish
        '';
      };
    };
}
