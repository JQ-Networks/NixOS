{ nodes, config, pkgs, lib, ... }:
let
  utils = import ./utils.nix {
    inherit nodes config lib;
  };
in lib.mkIf (utils.cfg.enable && utils.cfg.caCertificate != null) {
  environment.etc."kubernetes/pki/ca.crt" = {
    mode = "0600";
    text = builtins.readFile utils.cfg.caCertificate;
  };
}
