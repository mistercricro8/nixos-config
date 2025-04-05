{
  description = "A flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self, nixpkgs, ... }@inputs: let 
    system = "x86_64-linux";
  in {
    devShells."${system}".default = let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      extensions = inputs.vscode-extensions.extensions.${system};
    in pkgs.mkShell {
      packages = with pkgs; [
        (vscode-with-extensions.override {
          vscode = vscodium;
          vscodeExtensions =
          (with extensions.vscode-marketplace; [
            vsextpkgs
          ]) ++ (with pkgs.vscode-extensions; [
            github.copilot
            jnoortheen.nix-ide
            arrterian.nix-env-selector
            vspkgs
          ]);
        })
        basepkgs
      ];
      buildInputs = [ pkgs.bashInteractive ];
      initHook = ''
      inithooks
        zsh
      '';
    };
  };
}