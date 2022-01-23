# Firewall
# credit zhaofeng
# Mainly controlled by router

{ config, pkgs, lib, ... }:
with lib;
with builtins;
let
  cfg = config.jq-networks.supplemental.firewall;
  genconfig = import ./genconfig.nix { inherit lib; };

  mkChain = description: mkOption {
    inherit description;
    default = {};
    type = chainType;
  };

  mkTable = name: mkOption {
    description = "${name} table";
    default = {};
    type = types.submodule {
      options = {
        chains = mkOption {
          description = "Chains";
          type = types.attrsOf chainType;
          default = {};
        };
        prepends = mkOption {
          description = "Extra configs to be prepended";
          default = [];
          type = types.listOf types.str;
        };
        appends = mkOption {
          description = "Extra configs to be appended";
          default = [];
          type = types.listOf types.str;
        };
      };
    };
  };

  mkTableAttr = name: {
    name = name;
    value = mkTable name;
  };

  # tables <- list of mkTableAttr
  mkDomain = name: tables: let
  in mkOption {
    description = "${name}";
    default = {};
    type = types.submodule {
      options = tables;
    };
  };

  ruleType = types.submodule {
    options = let
      mkFilter = description: mkOption {
        inherit description;
        default = null;
        type = types.nullOr (types.either
        (types.either types.str types.ints.unsigned)
        (types.listOf (types.either types.str types.ints.unsigned)));
      };
      mkStr = description: mkOption {
        inherit description;
        default = null;
        type = types.nullOr types.str;
      };
    in {
      module = mkStr "Load module";
      description = mkStr "Description";

      interface = mkFilter "Incoming interface";
      outerface = mkFilter "Outgoing interface";
      proto = mkFilter "Protocol";
      sport = mkFilter "Source port";
      dport = mkFilter "Destination port";
      saddr = mkFilter "Source address";
      daddr = mkFilter "Destination address";
      mark = mkFilter "Match mark";

      extraFilters = mkOption {
        description = "Extra filters";
        default = "";
        type = types.str;
      };

      action = mkOption {
        description = "Action";
        default = "ACCEPT";
        type = types.str;
        #type = types.enum [ "ACCEPT" "REJECT" "DROP" "DNAT" "SNAT" "MASQUERADE" "MARK" "jump" ];
      };
      args = mkOption {
        description = "Extra arguments following the action";
        default = null;
        type = types.nullOr types.str;
      };
    };
  };

  chainType = types.submodule {
    options = {
      prepends = mkOption {
        description = "Rules to prepend";
        default = [];
        type = types.listOf types.str;
      };
      appends = mkOption {
        description = "Rules to append";
        default = [];
        type = types.listOf types.str;
      };
      rules = mkOption {
        description = "Rules";
        default = [];
        type = types.listOf ruleType;
      };
      rulesAppend = mkOption {
        description = "Rules to append";
        default = [];
        type = types.listOf ruleType;
      };
      policy = mkOption {
        description = "Policy";
        default = null;
        type = types.nullOr types.str;
      };
    };
  };

  # FIXME: Remove fixed chains
  commonDomTables = let
    filter = mkTableAttr "filter";
    nat = mkTableAttr "nat";
    mangle = mkTableAttr "mangle";
  in listToAttrs [ filter nat mangle ];
in
{
  options = {
    jq-networks.supplemental.firewall = {
      enable = mkOption {
        description = "Enable the ferm firewall";
        default = false;
        type = types.bool;
      };
      # dom -> table -> chain
      ip = mkDomain "ip" commonDomTables;
      ip6 = mkDomain "ip6" commonDomTables;

      # Simple options
      filterInputRules = mkOption {
        description = "Common INPUT rules for both v4 and v6";
        default = [];
        type = types.listOf ruleType;
      };

      extraConfigs = mkOption {
        description = "Extra configs to be added";
        default = [];
        type = types.listOf types.str;
      };
      extraConfigsPrepend = mkOption {
        description = "Extra configs to be prepended";
        default = [];
        type = types.listOf types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.enable = false;
    services.ferm.enable = true;

    # Simple TCP rules
    jq-networks.supplemental.firewall.ip.filter.chains.input.rules = cfg.filterInputRules;
    jq-networks.supplemental.firewall.ip6.filter.chains.input.rules = cfg.filterInputRules;

    environment.systemPackages = with pkgs; [
      iptables
    ];

    #environment.etc."ferm.conf".text 
    services.ferm.config = ''
      ${concatStringsSep "\n" cfg.extraConfigsPrepend}
      ${genconfig.domain "ip" cfg.ip}
      ${genconfig.domain "ip6" cfg.ip6}
      ${concatStringsSep "\n" cfg.extraConfigs}
    '';
  };
}
