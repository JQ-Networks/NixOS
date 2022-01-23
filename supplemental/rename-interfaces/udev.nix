{ lib, config, ... }:

with builtins;
let
  cfg = config.jq-networks.supplemental.rename-interfaces;

  renameInterface = mac: ifname:
    "SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"${mac}\", NAME=\"${ifname}\"";
in {
  config = lib.mkIf (cfg.enable && cfg.method == "udev")
    (if (lib.versionAtLeast lib.version "21.03pre") then {
      services.udev.initrdRules = concatStringsSep "\n"
        (lib.mapAttrsToList (name: mac: renameInterface mac name) cfg.interfaces);
    } else {
      services.udev.extraRules = concatStringsSep "\n"
        (lib.mapAttrsToList (name: mac: renameInterface mac name) cfg.interfaces);
    });
}
