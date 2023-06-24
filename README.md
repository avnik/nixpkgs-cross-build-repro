## NixOS cross build playground

Simplified cross-environment for build problematic packages (which don't cross build cleanly)

## How to reproduce

```sh
# nix build ".#crossed" -L --cores 16 -j 1
```
