{ inputs, ... }:
{
  flake.factories.nixos."development/ai" =
    {
      user ? "cricro",
    }:
    { pkgs, lib, ... }:
    let
      llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      omp = llmPkgs.omp;
      # TODO: remove whenever the flake adds fish completions or
      # the package gets to nixpkgs
      ompWithCompletions = pkgs.symlinkJoin {
        name = "omp-with-fish-completions-${omp.version}";
        paths = [ omp ];
        postBuild = ''
          mkdir -p $out/share/fish/vendor_completions.d
          HOME=$TMPDIR ${lib.getExe omp} completions fish > $out/share/fish/vendor_completions.d/omp.fish
        '';
      };
    in
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        lib.flatten [
          (with llmPkgs; [
            opencode
            copilot-cli
            antigravity-cli
            orca
          ])
          [ ompWithCompletions ]
          (with pkgs; [
            tgrep
          ])
        ]
      );

      nixpkgs.config.android_sdk.accept_license = true;

      dotfiles.profiles = [
        "opencode"
        "gemini"
        "copilot"
        "omp"
        "orca-dms"
      ];
    };
}
