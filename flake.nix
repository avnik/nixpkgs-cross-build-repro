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
      imports = [];
      flake = { lib, ...}: {
        ghaf.nixos = [
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

            vmConfigs = {}; # Populated with VMs wrapped into nixosSystem (and injected cross if needed)
            instance = {}; # populated with nixosSystem, including .system (and injected cross if needed)
        };
      };
      perSystem = { lib, self', inputs', system, pkgs, ... }: {
        packages = let
           combos = lib.cartesianProductOfSets { variant = builtins.attrNames self.variants; board = builtins.attrNames self.boards; };
           combos' = map (c: { name = "${c.board}-${c.variant}"; board = self.boards.${c.board}; variant = self.variant.${c.variant}; targetSystem = self.boards.${c.board}.system; }) combos;
           mkHostStatement = targetSystem: [{ nixpkgs.hostPlatform.system = targetSystem; }];
           mkCrossStatement = targetSystem: buildSystem:
             if targetSystem == buildSystem
                then []
                else [
                    { nixpkgs.buildPlatform.system = buildSystem; }
                    # FIXME: import cross-overlay here
                ];
           # Wrapper for lib.nixosSystem, which able to detect cross-systems, and inject proper statements     
           mkTargetSystem = { nixosModules, targetSystem, buildSystem }:
             lib.nixosSystem {
                system = targetSystem;
                modules = nixosModules ++
                  (mkHostStatement targetSystem) ++
                  (mkCrossStatement targetSystem buildSystem);
             };
           mkSystem = { name, board, variant, targetSystem }:
             { name = name;
               value = mkTargetSystem {
                 nixosModules = board.nixos ++ variant ++ mkHostStatement targetSystem ++ mkCrossStatement targetSystem system;
               };
             };
           toplevels = {};
           flashScripts = {};
          in toplevels // flashScripts;
          # All packages should be derived
          # yield "${board}-${crossOrNative}-${variant}}
#          fakeOrinBoard-cross-toplevel = self.nixosConfigurations.crossed.config.system.build.toplevel;
#          fakeOrinBoard-cross-flashscript = "";
      };
    };
}
