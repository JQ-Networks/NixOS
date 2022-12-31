{ lib }:
with lib;
with builtins;
with lib.types;
let
  familyType = [ "ip" "ip6" "inet" "arp" "bridge" "netdev"];

  compositeType = nullOr (either
      (either str ints.unsigned)
      (listOf (either str ints.unsigned)));

  mkComposite = description: mkOption {
    inherit description;
    default = null;
    type = compositeType;
  };
  mkStr = description: mkOption {
    inherit description;
    default = null;
    type = nullOr str;
  };
  mkSet = description: mkOption {
    inherit description;
    default = {};
    type = set;
  };
in
rec {
  tableType = types.submodule {
    options = {
      family = mkOption {
        description = "family type";
        type = enum familyType;
      };
      name = mkStr "table name";
      sets = mkOption {
        description = "Sets";
        type = attrsOf setType;
        default = {};
      };
      maps = mkOption {
        description = "Maps";
        type = attrsOf mapType;
        default = {};
      };
      chains = mkOption {
        description = "Chains";
        type = attrsOf chainType;
        default = {};
      };
    };
  };

  setType = types.submodule {  # meter is a set
    options = {
      name = mkStr "set name";
      type = mkStr "set type";
      typeOf = mkStr "set typeOf. Ignores type field when this is set.";
      flags = mkStr "set flags";
      elements = mkComposite "set elements";
      comment = mkStr "comment";
      extraConfigs = mkOption {
        description = ''extra options
          See https://wiki.nftables.org/wiki-nftables/index.php/Sets for more options.
        '';
        type = lines;
        default = "";
      };
    };
  };

  mapType = types.submodule {  # vmap is a map
     options = {
      name = mkStr "map name";
      type = mkStr "set type";
      typeOf = mkStr "set typeOf. Ignores type field when this is set.";
      elements = mkComposite "map elements";
      comment = mkStr "comment";
      extraConfigs = mkOption {
        description = ''extra options
          See https://wiki.nftables.org/wiki-nftables/index.php/Sets for more options.
        '';
        type = lines;
        default = "";
      };
    };
  };

  chainType = types.submodule {
    options = {
      name = mkStr "chain name";
      type = mkOption {
        description = "chain type";
        type = nullOr (enum ["filter" "nat" "route"]);
        default = null;
      };
      hook = mkOption {
        description = "hooks";
        type = enum ["prerouting" "input" "forward" "output" "postrouting" "ingress" "egress"];
        default = null;
      };
      policy = mkStr "default policy";

      rules = mkOption {
        description = "rules";
        type = listOf ruleType;
        default = [];
      };
      priority = mkComposite ''priority: number of predefined strings
      See https://man.archlinux.org/man/nft.8 for more info.
      raw	-300
      mangle	-150
      dstnat	-100
      filter	0
      security	50
      srcnat	100
      '';
      comment = mkStr "comment";
    };
  };

  ruleType = attrsOf compositeType;
}
