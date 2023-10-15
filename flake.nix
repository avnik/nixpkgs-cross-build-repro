{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs";
        flake-parts = {
          url = "github:hercules-ci/flake-parts";
          inputs.nixpkgs-lib.follows = "nixpkgs";
        };
        nix-ocaml = {
          url = "github:nix-ocaml/nix-overlays";  
          inputs.nixpkgs.follows = "nixpkgs";
        };
    };
    outputs = { self, flake-parts, ...}@inputs:  flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      flake = { lib, ...}: {
        nixosConfigurations = {
          crossed = lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              {
                nixpkgs.hostPlatform.system = "aarch64-linux";
                nixpkgs.buildPlatform.system = "x86_64-linux";
                nixpkgs.overlays =  [ 
                  inputs.nix-ocaml.overlays.default
                  (final: prev: {
                     caml-crush = final.callPackage ./caml-crush.nix { };
                  })
                ];
              }
              ({ pkgs, ...}: {
                environment.systemPackages = with pkgs; [
                  # List problematic packages here
                  caml-crush 
                ];
                boot.isContainer = true; # Don't build kernel and other slow things
              })
            ];
          };
        };
      };
      perSystem = { self', inputs', system, pkgs, ... }: {
        packages = {
         crossed = self.nixosConfigurations.crossed.config.system.build.toplevel;
        };
      };
    };
}
