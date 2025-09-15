{
  description = "NixOS configuration.";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
    };
    catppuccin-grub = {
      url = "github:catppuccin/grub";
      flake = false;
    };
    vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/hyprland";
    };
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      sops-nix,
      flake-utils,
      catppuccin,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      mkHMconfig = homefile: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = {
            inherit inputs;
            rootCfgPath = ./.;
          };
          users.cricro = homefile;
        };
      };
      allPkgs = nixpkgs.lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );
    in
    flake-utils.lib.eachSystem systems (system: {
      devShells.default =
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        pkgs.mkShell {
          packages = with pkgs; [
            # terraform
            oci-cli
          ];
          buildInputs = with pkgs; [ bashInteractive ];
          shellHook = ''
            export TF_PLUGIN_CACHE_DIR=$HOME/.terraform.d/plugin-cache
          '';
        };
    })
    // {
      nixosConfigurations = {
        cricro-pc =
          let
            system = "x86_64-linux";
            pkgs = allPkgs.${system};
          in
          nixpkgs.lib.nixosSystem {
            inherit system;
            inherit pkgs;
            modules = [
              ./hosts/cricro-pc/configuration.nix
              catppuccin.nixosModules.catppuccin
              sops-nix.nixosModules.sops
              (import ./hosts/modules/overlays/default.nix)
              home-manager.nixosModules.home-manager
              (mkHMconfig ./home-manager/per-home/cricro-pc.nix)
            ];
            specialArgs = { inherit inputs; };
          };
        cricro-laptop =
          let
            system = "x86_64-linux";
            pkgs = allPkgs.${system};
          in
          nixpkgs.lib.nixosSystem {
            inherit system;
            inherit pkgs;
            modules = [
              ./hosts/cricro-laptop/configuration.nix
              catppuccin.nixosModules.catppuccin
              sops-nix.nixosModules.sops
              (import ./hosts/modules/overlays/default.nix)
              home-manager.nixosModules.home-manager
              (mkHMconfig ./home-manager/per-home/cricro-laptop.nix)
            ];
            specialArgs = { inherit inputs; };
          };
        cricro-vm =
          let
            system = "aarch64-linux";
            pkgs = allPkgs.${system};
          in
          nixpkgs.lib.nixosSystem {
            inherit system;
            inherit pkgs;
            modules = [
              ./hosts/cricro-vm/configuration.nix
              catppuccin.nixosModules.catppuccin
              sops-nix.nixosModules.sops
              (import ./hosts/modules/overlays/default.nix)
              # home-manager.nixosModules.home-manager
              # (mkHMconfig ./home-manager/per-home/cricro-vm.nix)
            ];
            specialArgs = { inherit inputs; };
          };
      };
    };
}
