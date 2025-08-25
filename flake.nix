{
  description = "NixOS configuration.";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {
        cricro-pc = nixpkgs.lib.nixosSystem {
          inherit system;
          inherit pkgs;
          modules = [
            ./hosts/cricro-pc/configuration.nix
            (import ./homes/cricro-pc/overlays.nix)
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };
                users.cricro = ./homes/cricro-pc/home.nix;
              };
            }
          ];
          specialArgs = { inherit inputs; };
        };
        cricro-laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          inherit pkgs;
          modules = [
            ./hosts/cricro-laptop/configuration.nix
            (import ./homes/cricro-pc/overlays.nix)
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };
                users.cricro = ./homes/cricro-laptop/home.nix;
              };
            }
          ];
          specialArgs = { inherit inputs; };
        };
      };
    };
}
