{ inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.vscode-extensions.overlays.default
  ];
}
