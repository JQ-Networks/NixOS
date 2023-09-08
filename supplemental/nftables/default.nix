# nftables DSL
# based on https://wiki.archlinux.org/title/nftables
# Special features:
# 1. If any field is empty (null, "", [], false) within ruleType, the rule entry is truncated.
# 2. use counter = true; for counter argument.
# 3. use comment = "asdasd"; for comments.
# 4. use action = "accept"; for actions like "accept".

{ config, pkgs, lib, ... }:
with lib;
with builtins;
let
  cfg = config.jq-networks.supplemental.nftables;
  tableType = (import ./types.nix { inherit lib; }).tableType;
  renderConfig = (import ./render.nix { inherit lib; }).genConf;
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

    assertions = mkIf cfg.enable [
      {
        assertion = ((exec "${pkgs.nftables}/bin/nft -c -f ${ruleSetFile}").exitCode == 0);
        message = "NFT rule check failed.";
      }
    ];
  };
}
