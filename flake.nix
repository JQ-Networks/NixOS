{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
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
            unstable = (import unstable { system = final.system; config.allowUnfree = true;});
            master = (import nixpkgs-master { system = final.system; config.allowUnfree = true;});
          }
        )
        # (final: prev: (indexyz.overlay.${final.system} final prev))
        # https://github.com/DavHau/pypi-deps-db

        (final: prev: { mach-nix = import mach-nix { pkgs = import nixpkgs {}; pypiDataRev = "42a6f18b7abafe97d73cc8045d6357915c5ecf77"; pypiDataSha256 = "sha256-uKf8bMR6prNIuvXtoNyKH7gfd1pBAeHQ6l0i0SSh9IA="; }; })
        indexyz.overlay."x86_64-linux"
        (
          final: prev: {
            mtg = self.packages."x86_64-linux".mtg;
            xray = self.packages."x86_64-linux".xray;
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
      };
    };
}
