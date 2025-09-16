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
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
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
      vscode-server,
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
            rootCfgPathAbs = "/home/cricro/nixos-config";
          };
          users.cricro = homefile;
        };
      };
      mkNixosConfig =
        hostname: system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          inherit pkgs;
          modules = [
            ./hosts/per-host/${hostname}.nix
            catppuccin.nixosModules.catppuccin
            vscode-server.nixosModules.default
            sops-nix.nixosModules.sops
            (import ./hosts/modules/overlays/default.nix)
            home-manager.nixosModules.home-manager
            (mkHMconfig ./home-manager/per-home/${hostname}.nix)
          ];
          specialArgs = {
            inherit inputs;
            rootCfgPath = ./.;
          };
        };
      #allPkgs = nixpkgs.lib.genAttrs systems (
      #  system:
      #  import nixpkgs {
      #    inherit system;
      #    config.allowUnfree = true;
      #  }
      #);
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
        cricro-pc = mkNixosConfig "cricro-pc" "x86_64-linux";
        cricro-laptop = mkNixosConfig "cricro-laptop" "x86_64-linux";
        cricro-vm = mkNixosConfig "cricro-vm" "aarch64-linux";
      };
    };
}
