{ nixpkgs, nixpkgs-unstable, ... }:
with nixpkgs;
let
  nvfetcherOut = callPackage ../_sources/generated.nix { };
in
{
  mtg = callPackage ./mtg { lib = nixpkgs.lib; source = nvfetcherOut.mtg; };
  clash-premium = callPackage ./clash-premium { source = nvfetcherOut.clash-premium; };
}
