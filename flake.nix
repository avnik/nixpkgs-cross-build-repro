{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs";
        flake-parts = {
          url = "github:hercules-ci/flake-parts";
          inputs.nixpkgs-lib.follows = "nixpkgs";
        };
    };
    outputs = { self, flake-parts, ...}@inputs:  flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      imports = [ ./impl/packages.nix ./impl/targets.nix ];
      flake = { lib, ...}: {
        global.nixos = [
              ({ pkgs, ...}: {
                environment.systemPackages = with pkgs; [
                  # List problematic packages here
                  gnome.zenity
                ];
              })
           ];
        virtualMachines = {
            netvm = {
            };
        };
        variants = {
            debug = { ghaf.debug = true; };
            netvm = { ghaf.debug = true; ghaf.netvm = true; };
            release = { ghaf.debug = false; ghaf.release = true; };
        };
        boards.fakeOrinBoard = {
            system = "aarch64-linux";
            nixos = [{
                boot.isContainer = true; # Don't build kernel and other slow things (because it is prototyping)
            }];
            flashScript = { image, pkgs, system, ...}: pkgs.runLocal "flashscript" { }
              ''
              '';
        };
      };
    };
}
