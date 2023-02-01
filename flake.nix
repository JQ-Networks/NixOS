{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs";
    indexyz = {
      url = "github:X01A/nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pypi-deps-db = {
      url = "github:DavHau/nix-pypi-fetcher-2";
      flake = false;
    };
    mach-nix = {
      url = "github:DavHau/mach-nix?ref=3.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pypi-deps-db.follows = "pypi-deps-db";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixpkgs-master, indexyz, mach-nix, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          packages = import ./pkgs { nixpkgs = pkgs; };
        in
        {
          overlays = [
            (
              final: prev: {
                unstable = (import nixpkgs-unstable { system = final.system; config.allowUnfree = true; });
                master = (import nixpkgs-master { system = final.system; config.allowUnfree = true; });
              }
            )
            # (final: prev: (indexyz.overlay.${final.system} final prev))
            # https://github.com/DavHau/pypi-deps-db

            (final: prev: { mach-nix = mach-nix.lib.${final.system}; })
            indexyz.overlay.${system}
            (final: prev: packages)
          ];
          inherit packages;
        }
      ) // {
      nixosModules = {
        jq-networks = { system, ... }: {
          imports =
            # let
            #   enablePackages = (
            #     { ... }: {
            #       nixpkgs.overlays = self.overlays.${system};
            #     }
            #   );
            # in
            [
              ./default.nix
            ];
        };
        lib = { lib, pkgs, ... }: (import ./utils { inherit lib pkgs; });
      };
    };
}
