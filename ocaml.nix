# `nixpkgs` here are the `nixpkgs` sources, i.e. the flake input
{nix-ocaml, nixpkgs}:

let
  overlayOCamlPackages = attrs: import "${nix-ocaml}/ocaml/overlay-ocaml-packages.nix" (attrs // {
    inherit nixpkgs;
  });
in

# This might be helfpul later:
# https://www.reddit.com/r/NixOS/comments/6hswg4/how_do_i_turn_an_overlay_into_a_proper_package_set/
let ocamlOverlay = (self: super:

let
  inherit (super)
    lib
    stdenv
    fetchFromGitHub
    callPackage
    fetchpatch;

  staticLightExtend = pkgSet: pkgSet.extend (self: super:
    super.lib.overlayOCamlPackages {
      inherit super;
      overlays = [ (super.callPackage "${nix-ocaml}/static/ocaml.nix" { }) ];
      updateOCamlPackages = true;
    });
in

(overlayOCamlPackages {
  inherit super;
  overlays = [
    (callPackage "${nix-ocaml}/ocaml" {
      inherit nixpkgs;
      super-opaline = super.opaline;
      oniguruma-lib = super.oniguruma;
      libgsl = super.gsl;
    })
  ];
}));
  static-overlay = import "${nix-ocaml}/static";
  no-static-overlay = (self: super:
    {
        gmp-oc = super.gmp;
        libev-oc = super.libev;
        libffi-oc = super.libffi-oc;
        libpq = super.postgresql;
        lz4-oc = super.lz4;
        openssl-oc = super.openssl;
        pcre-oc = super.pcre;
        rdkafka-oc = super.rdkafka;
        sqlite-oc = super.sqlite-oc;
        zlib-oc = super.zlib;
        zstd-oc = super.zstd;
    });
  cross-overlay = (self: super:
    if super.buildPlatform != super.hostPlatform then
    overlayOCamlPackages {
      inherit super;
      overlays = super.callPackage "${nix-ocaml}/cross/ocaml.nix" {
        inherit (super) buildPackages;
      };
      updateOCamlPackages = true;
     } else {});
  composeExtensions = f: g: final: prev: let
    fApplied = f final prev;
    prev' = prev // fApplied;
  in
    fApplied // g final prev';
  ordered = [ ocamlOverlay cross-overlay no-static-overlay ];  
  combined = builtins.foldl' composeExtensions (_: _: {}) ordered;
in
  combined
