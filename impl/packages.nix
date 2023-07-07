{ lib, self, ...}:
{
  perSystem = { self', system, ... }: {
    packages = { foo = self'.targets.fakeOrinBoard; };
  };
}
