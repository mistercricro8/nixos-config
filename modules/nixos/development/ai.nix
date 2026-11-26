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
      # TODO: remove whenever llm-agents.nix stops patchelf-ing agent-browser-linux-x64
      # (patchelf changes its sha256, breaking orcad-template/orcad-template.json validation)
      orcaFixed = llmPkgs.orca.overrideAttrs (
        old:
        assert lib.hasInfix "! -name orcad-template" old.postFixup;
        {
          postFixup = builtins.replaceStrings
            [ "! -name orcad-template" ]
            [ "! -name orcad-template ! -name agent-browser-linux-x64" ]
            old.postFixup;
        }
      );
    in
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        lib.flatten [
          (with llmPkgs; [
            antigravity-cli
          ])
          [
            ompWithCompletions
            orcaFixed
          ]
        ]
      );

      nixpkgs.config.android_sdk.accept_license = true;

      dotfiles.profiles = [
        "gemini"
        "omp"
        "agents"
        "orca-dms"
      ];
    };
}
