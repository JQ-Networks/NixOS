{
  inputs = {
    nixpkgs.url = "github:JQ-Networks/nixpkgs/nixos-22.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs";
    indexyz.url = "github:X01A/nixos";
    mach-nix.url = "github:DavHau/mach-nix?ref=3.4.0";
  };
  outputs = inputs@{ self, nixpkgs, unstable, nixpkgs-master, indexyz, mach-nix, ... }:
    {
      overlays = [
        (
          final: prev: {
            unstable = (import unstable { system = final.system; config.allowUnfree = true; });
            master = (import nixpkgs-master { system = final.system; config.allowUnfree = true; });
          }
        )
        # (final: prev: (indexyz.overlay.${final.system} final prev))
        # https://github.com/DavHau/pypi-deps-db

        (final: prev: { mach-nix = mach-nix.lib.${final.system}; })
        indexyz.overlay."x86_64-linux"
        (
          final: prev: {
            mtg = self.packages."x86_64-linux".mtg;
            xray = self.packages."x86_64-linux".xray;
            sing-box = self.packages."x86_64-linux".sing-box;
          }
        )
      ];
      packages."x86_64-linux" =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
        in
          import ./pkgs { nixpkgs = pkgs; };
      nixosModules = {
        jq-networks = { ... }: {
          imports =
            let
              enableUnstable = (
                { ... }: {
                  nixpkgs.overlays = self.overlays;
                }
              );
            in
              [
                ./default.nix
                enableUnstable
              ];
        };
        lib = { lib, pkgs, ... }: (import ./utils { inherit lib pkgs; });
      };
    };
}
