{ lib, self, ...}:
{
  perSystem = { config, self', system, ... }: {
    packages = lib.mapAttrs' (name: target: { 
          name = "${name}-system-image";
          value = target.instance.config.system.build.toplevel;
        }) config.targets;
  };
}
