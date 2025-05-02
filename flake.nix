{
  description = "NixOS configuration.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:khaneliman/khanelivim";
    };
    clipboard-sync = {
      url = "github:dnut/clipboard-sync";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      clipboard-sync,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        cricro-pc = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/cricro-pc/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
                users.cricro = ./homes/cricro-pc/home.nix;
              };
            }
            clipboard-sync.nixosModules.default
          ];
          specialArgs = { inherit inputs; };
        };
        cricro-laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/cricro-laptop/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
                users.cricro = ./homes/cricro-laptop/home.nix;
              };
            }
            clipboard-sync.nixosModules.default
          ];
        };
      };
    };
}

