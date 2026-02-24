{
  description = "NixOS configuration.";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-25.11";
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
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
    };
    vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions/8239c1145f39fe88dd1f2ed3db17b2e6e30beb2b";
    };
    nur = {
      url = "github:nix-community/NUR";
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
      flake-utils,
      sops-nix,
      vscode-server,
      catppuccin,
      nur,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      mkHMconfig = homeFile: configName: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = {
            inherit inputs configName;
            customLib = {
              utils = import ./lib/utils.nix { };
              constants = import ./lib/constants.nix { };
              private = import ./lib/private.nix { };
            };
            rootCfgPath = ./.;
            rootCfgPathAbs = "/home/cricro/nixos-config";
          };
          users.cricro = homeFile;
        };
      };
      mkNixosConfig =
        configName: system: hostName:
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
            nur.modules.nixos.default
            catppuccin.nixosModules.catppuccin
            sops-nix.nixosModules.sops
            vscode-server.nixosModules.default
            home-manager.nixosModules.home-manager
            ./hosts/cricro-${configName}.nix
            (import ./hosts/modules/overlays/default.nix)
            (mkHMconfig ./home-manager/cricro-${configName}.nix configName)
          ];
          specialArgs = {
            inherit inputs configName hostName;
            customLib = {
              utils = import ./lib/utils.nix { };
              constants = import ./lib/constants.nix { };
              private = import ./lib/private.nix { };
            };
            rootCfgPath = ./.;
            rootCfgPathAbs = "/home/cricro/nixos-config";
          };
        };
    in
    flake-utils.lib.eachSystem systems (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            sops-nix.packages.${system}.sops-import-keys-hook
          ];
          sopsPGPKeyDirs = [
            ./keys
          ];
          packages = with pkgs; [
            opentofu
            oci-cli
            jq
            ssh-to-pgp
            sops
            nix-output-monitor
            git-crypt
          ];
          buildInputs = with pkgs; [ bashInteractive ];
          shellHook = ''
            source ./apps/shell-hook/main.sh
          '';
        };
      }
    )
    // {
      nixosConfigurations = {
        cricro-pc = mkNixosConfig "pc" "x86_64-linux" "cricro-pc";
        cricro-laptop = mkNixosConfig "laptop" "x86_64-linux" "cricro-laptop";
        cricro-l2 = mkNixosConfig "l2" "x86_64-linux" "cricro-l2";
        cricro-vm = mkNixosConfig "vm" "aarch64-linux" "cricro-vm";
        bootstrap-x86 = mkNixosConfig "bootstrap" "x86_64-linux" "bootstrap";
        bootstrap-aarch64 = mkNixosConfig "bootstrap" "aarch64-linux" "bootstrap";
        cricro-nixd = mkNixosConfig "nixd" "x86_64-linux" "nixd";
      };
    };
}
