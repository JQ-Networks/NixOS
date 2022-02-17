{ nixpkgs, ... }:
with nixpkgs;
{
  mtg = callPackage ./mtg { lib = nixpkgs.lib; };
  xray = callPackage ./xray { lib = nixpkgs.lib; buildGoModule = buildGo117Module; };
}
