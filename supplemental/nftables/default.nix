# nftables DSL
# based on https://wiki.archlinux.org/title/nftables

{ config, pkgs, lib, ... }:
with lib;
with builtins;
let
  cfg = config.jq-networks.supplemental.nftables;
  tableType = (import ./types.nix).tableType;
  renderConfig = (import ./render.nix).genConf;
  ruleSetFile = toFile "nftables.rule" (renderConfig cfg.config);
in
{
  options = {
    jq-networks.supplemental.nftables = {
      enable = mkOption {
        description = "Enable the nftables";
        default = false;
        type = types.bool;
      };
      config = mkOption {
        description = "nftables config";
        type = types.attrsOf tableType;
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.enable = false;
    networking.nftables.enable = true;
    networking.nftables.ruleset = renderConfig cfg.config;

    environment.systemPackages = with pkgs; [
      nftables
    ];
  };
}
