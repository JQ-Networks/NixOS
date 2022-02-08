{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    indexyz.url = "github:X01A/nixos";
    mach-nix.url = "github:DavHau/mach-nix?ref=3.3.0";
  };
  outputs = inputs@{ self, nixpkgs, unstable, indexyz, mach-nix, ... }: {
    overlays = [
      (
        final: prev: {
          unstable = (import unstable { system = final.system; });
        }
      )
      # (final: prev: (indexyz.overlay.${final.system} final prev))
      (final: prev: { mach-nix = import mach-nix { pkgs = import nixpkgs {}; pypiDataRev = "fc8e41f3c2e219e644e3784b68bda8dd31a29178"; pypiDataSha256 = "0s8as6zm7kci1y78cw5f69la0njk9am3yj2y8g710nvcg60pr3bd";}; })
      indexyz.overlay."x86_64-linux"
    ];
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
