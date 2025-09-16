# TODO this

(fetchTarball {
      url = "https://github.com/nix-community/nixos-vscode-server/tarball/master";
      sha256 = "sha256:1rdn70jrg5mxmkkrpy2xk8lydmlc707sk0zb35426v1yxxka10by";
    })
  ];

  boot.binfmt.emulatedSystems = [
    "x86_64-linux"
  ];

  services.vscode-server.enable = true;