{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs";
        flake-parts = {
          url = "github:hercules-ci/flake-parts";
          inputs.nixpkgs-lib.follows = "nixpkgs";
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
              }
              ({ pkgs, ...}: {
                environment.systemPackages = with pkgs; [
                  # List problematic packages here
                  gnome.zenity
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
