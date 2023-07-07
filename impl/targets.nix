{ lib, flake-parts-lib, self, ...}:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;
  genTargets = { boards, variants, system }: lib.mapAttrs' (name: value: {
      inherit name; # Should be "board-variant-native" or "board-variant-cross"
      value = { };  # just a stub
    }) boards; 
  targetType = types.submodule {
    options = {
      hostSystem = mkOption {
        type = types.str;
        internal = true;
      };
      instance = mkOption {
        type = types.package;
        internal = true;
      };
      vmInstances = mkOption {
        type = types.lazyAttrsOf types.package;
        internal = true;
        default = {};
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
