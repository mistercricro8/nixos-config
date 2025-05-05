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
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs
    , home-manager
    , ...
    } @ inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        cricro-pc = nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ./hosts/cricro-pc/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inputs = inputs; };
                users.cricro = ./homes/cricro-pc/home.nix;
              };
            }
          ];
          specialArgs = { };
        };
        cricro-laptop = nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ./hosts/cricro-laptop/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inputs = inputs; };
                users.cricro = ./homes/cricro-laptop/home.nix;
              };
            }
          ];
          specialArgs = { };
        };
      };
    };
}
