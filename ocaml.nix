# `nixpkgs` here are the `nixpkgs` sources, i.e. the flake input
{nix-ocaml, nixpkgs}:

let
  crossOcamlHack = super:
    let table = {
        "aarch64-linux" = "aarch64-multiplatform";
        "riscv64" = "riscv64";
       };
       pkgs = import nixpkgs {
        inherit (super.buildPlatform) system;
        overlays = [
          nix-ocaml.overlays.default
        ];
      };
      in pkgs.pkgsCross.${table.${super.stdenv.hostPlatform.system}};
in

(self: super: {
  caml-crush =
    (if super.stdenv.hostPlatform != super.stdenv.buildPlatform
      then (crossOcamlHack super).callPackage ./caml-crush.nix {
        # Kludge: pass coccinelle from main nixpkgs, coccinelle unbuildable with overlay
        coccinelle = nixpkgs.legacyPackages.${super.buildPlatform.system}.coccinelle;
      }
      else super.callPackage ./caml-crush.nix { }); 
  })

