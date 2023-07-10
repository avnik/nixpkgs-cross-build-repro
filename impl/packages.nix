{ lib, self, ...}:
{
  perSystem = { config, self', system, ... }: {
    packages = lib.mapAttrs' (name: target: { 
          name = "${name}-system-image";
          value = builtins.trace (builtins.toString target.instance.config.toplevel) target.instance.config.toplevel;
        }) config.targets;
  };
}
