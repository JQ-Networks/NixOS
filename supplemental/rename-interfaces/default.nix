{ lib, config, ... }:
with builtins;
let
  cfg = config.jq-networks.supplemental.rename-interfaces;
  types = lib.types;
in {
  imports = [
    ./udev.nix
    ./networkd.nix
  ];

  options = {
    jq-networks.supplemental.rename-interfaces = {
      enable = lib.mkOption {
        description = "Rename network interfaces based on MAC address";
        type = types.bool;
        default = false;
      };
      interfaces = lib.mkOption {
        description = "Interfaces";
        example = {
          "wan" = "11:45:14:19:19:81";
        };
        type = types.attrsOf types.str;
      };
      method = lib.mkOption {
        description = "Method to rename the interfaces";
        type = types.enum [ "udev" "networkd" ];
        default = "networkd";
      };
    };
  };
}
