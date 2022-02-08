{ nixpkgs, ... }:
with nixpkgs;
{
  mtg = callPackage ./mtg {lib = nixpkgs.lib;};
}
