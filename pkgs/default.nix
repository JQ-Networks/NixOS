{ nixpkgs, ... }:
with nixpkgs;
let
  nvfetcherOut = callPackage ../_sources/generated.nix { };
in
{
  mtg = callPackage ./mtg { lib = nixpkgs.lib; source = nvfetcherOut.mtg; };
  xray = callPackage ./xray { lib = nixpkgs.lib; buildGoModule = buildGo118Module; source = nvfetcherOut.xray; };
  sing-box = callPackage ./sing-box { lib = nixpkgs.lib; buildGoModule = buildGo118Module; source = nvfetcherOut.sing-box; };
}
