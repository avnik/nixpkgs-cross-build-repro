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
      imports = [ 
        ./impl/targets.nix
        ./impl/packages.nix
      ];
      flake = { lib, ...}: {
        global.nixosConfiguration = [
            {
                boot.isContainer = true; # Don't build kernel and other slow things (because it is prototyping)
                system.stateVersion = "23.05"; # Suppress warning
            }
           ];
        virtualMachines = {
            netvm = {
            };
        };
        variants = {
            debug.nixosConfiguration = [ /* { ghaf.debug = true; } */];
            netvm.nixosConfiguration = [/* { ghaf.debug = true; ghaf.netvm = true; } */];
            release.nixosConfiguration = [ /* { ghaf.debug = false; ghaf.release = true; } */];
        };
        boards.fakeOrinBoard = {
            system = "aarch64-linux";
            nixosConfiguration = [
              ({ pkgs, ...}: {
                environment.systemPackages = with pkgs; [
                  # List problematic packages here
                  #gnome.zenity
                  zathura
                ];
              })
            ];
            flashScript = { image, pkgs, system, ...}: pkgs.runLocal "flashscript" { }
              ''
              '';
        };
      };
    };
}
