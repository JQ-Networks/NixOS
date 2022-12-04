{ nixpkgs, ... }:
with nixpkgs;
{
  mtg = callPackage ./mtg { lib = nixpkgs.lib; };
  xray = callPackage ./xray { lib = nixpkgs.lib; buildGoModule = buildGo118Module; };
  sing-box = callPackage ./sing-box { lib = nixpkgs.lib; buildGoModule = buildGo118Module; };
}
