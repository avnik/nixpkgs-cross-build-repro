{ lib, flake-parts-lib, self, inputs, ...}:
let
  inherit (builtins)
    attrNames
    listToAttrs
    ;
  inherit (lib)
    mkOption
    types
    cartesianProductOfSets
    ;
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;
  mkHostStatement = targetSystem: [{ nixpkgs.hostPlatform.system = targetSystem; }];
  isCrossOrNative = targetSystem: buildSystem: if targetSystem == buildSystem then "native" else "cross";
  mkCrossStatement = targetSystem: buildSystem:
    if targetSystem == buildSystem
      then []
      else [
        { nixpkgs.buildPlatform.system = buildSystem; }
          # FIXME: import cross-overlay here
      ];
  mkTargetSystem = {
    nixosConfiguration,
    hostSystem,
    buildSystem
  }: lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = nixosConfiguration ++ mkHostStatement hostSystem ++ mkCrossStatement hostSystem buildSystem;
  };
  mkSystem = {
    nixosConfiguration,
    hostSystem,
    buildSystem,
    vmInstances
  }: mkTargetSystem { inherit nixosConfiguration hostSystem buildSystem; }; # FIXME Inject VMs here into nixosConfiguration
  genTargets = { boards, variants, system }: listToAttrs (map (item: 
      let
        boardName = item.board;
        variantName = item.variant;
        board = boards.${boardName};
        variant = variants.${variantName};
      in {
      name = "${boardName}-${variantName}-${isCrossOrNative board.system system}";
      value = rec {
        hostSystem = board.system;
        buildSystem = system;
        vmInstances = {}; # Stub
        nixosConfiguration = board.nixosConfiguration ++ variant.nixosConfiguration;
        instance = mkSystem {
          inherit hostSystem buildSystem vmInstances nixosConfiguration;
        };
      };
    }) (cartesianProductOfSets { board = attrNames boards; variant = attrNames variants; } ));
  targetType = types.submodule {
    options = {
      hostSystem = mkOption {
        type = types.str;
        internal = true;
      };
      buildSystem = mkOption {
        type = types.str;
        internal = true;
      };
      instance = mkOption {
        type = types.unspecified;
        internal = true;
        description = ''
          Instantiated host configuration, with target anb build systems, instantiated VMs, and cross-statements if needed
        '';
      };
      nixosConfiguration = mkOption {
        type = types.listOf types.raw;
        internal = true;
      };
      vmInstances = mkOption {
        type = types.lazyAttrsOf types.package;
        internal = true;
        default = {};
        description = ''
          Instantiated VM configuration, with target anb build systems, and cross-statements if needed
        '';
      };
    };
  };
in
{
  options = {  
    perSystem = mkPerSystemOption ({ system, config, ... }: {
        options = {
            targets = mkOption {
                type = types.lazyAttrsOf targetType;
                internal = true;
                default = genTargets { inherit (self) boards variants; inherit system; };   
            };
        };
    });
  };
}    
