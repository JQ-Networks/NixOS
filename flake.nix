{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs-master.url = "github:NixOS/nixpkgs";
    indexyz = {
      url = "github:X01A/nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, indexyz, mach-nix, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          pkgs-unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
          packages = import ./pkgs { nixpkgs = pkgs; nixpkgs-unstable = pkgs-unstable; };
        in
        {
          overlays = [
            (
              final: prev: {
                unstable = (import nixpkgs-unstable { system = final.system; config.allowUnfree = true; });
                # master = (import nixpkgs-master { system = final.system; config.allowUnfree = true; });
              }
            )
            # (final: prev: (indexyz.overlay.${final.system} final prev))
            # https://github.com/DavHau/pypi-deps-db
            indexyz.overlay.${system}
            (final: prev: packages)
          ];
          inherit packages;
        }
      ) // {
      nixosModules = {
        jq-networks = { system, ... }: {
          imports =
            [
              ./default.nix
            ];
        };
        lib = { lib, pkgs, ... }: (import ./utils { inherit lib pkgs; });
      };
    };
}
