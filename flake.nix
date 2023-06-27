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
        ghaf.nixos = [
              ({ pkgs, ...}: {
                environment.systemPackages = with pkgs; [
                  # List problematic packages here
                  gnome.zenity
                ];
              })
           ];
        boards.fakeOrinBoard = {
            system = "aarch64-linux";
            nixos = [{
                boot.isContainer = true; # Don't build kernel and other slow things
            }];
            flashScript = { image, pkgs, system, ...}: pkgs.runLocal "flashscript" { }
              ''
              '';

        };
      };
      perSystem = { self', inputs', system, pkgs, ... }: {
        packages = {
          # All packages should be derived  
          fakeOrinBoard-cross-toplevel = self.nixosConfigurations.crossed.config.system.build.toplevel;
          fakeOrinBoard-cross-flashscript = "";
        };
      };
    };
}
