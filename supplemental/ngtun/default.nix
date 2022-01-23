# credit zhaofeng
{ config, lib, pkgs, name, nodes, ... }:
with builtins;
let
  cfg = config.jq-networks.supplemental.ngtun;
  types = lib.types;

  endpointType = types.submodule {
    options = {
      ipv4 = lib.mkOption {
        description = ''
          The IPv4 endpoint (host only)
        '';
        type = types.nullOr types.str;
        default = null;
      };
      ipv6 = lib.mkOption {
        description = ''
          The IPv6 endpoint (host only)
        '';
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  globalType = types.submodule {
    options = {
      fwMark = lib.mkOption {
        description = ''
          Firewall mark
        '';
        type = types.ints.unsigned;
      };
      portBase = lib.mkOption {
        description = ''
          Port base

          For each tunnel, the listening port is computed as:
              Port Base + 100 * Self ID + Peer ID
        '';
        type = types.ints.unsigned;
      };
    };
  };
  nodeType = types.submodule {
    options = {
      id = lib.mkOption {
        description = ''
          Unique numerical ID for the node

          This ID must be unique among all nodes, or at least
          among the nodes it will have a tunnel to.
        '';
        type = types.nullOr types.ints.unsigned;
        default = null;
      };
      endpoint = lib.mkOption {
        description = ''
          Static endpoint

          It's possible for a node to have no static
          endpoints at all.
        '';
        type = endpointType;
        default = {};
      };
      privateKey = lib.mkOption {
        description = ''
          WireGuard private key for the node
        '';
        type = types.nullOr types.str;
        default = null;
      };
      groups = lib.mkOption {
        description = ''
          Groups this node belongs to
        '';
        type = types.listOf types.str;
        default = [];
      };
      supportedFamilies = lib.mkOption {
        description = ''
          List of address families supported by the node.

          Defaults to the families for which an endpoint
          is configured.
        '';
        type = types.listOf (types.enum ["ipv4" "ipv6"]);
        default = []
          ++ lib.optional (cfg.node.endpoint.ipv4 != null) "ipv4"
          ++ lib.optional (cfg.node.endpoint.ipv6 != null) "ipv6";
      };
      persistentKeepalive = lib.mkOption {
        description = ''
          Whether to enable persistent keep-alive for
          all tunnels on this node.

          For "auto", persistent keep-alive will be enabled:
          - If the tunnel will be established over an address
            family for which we don't have a static endpoint
        '';
        type = types.enum ["auto" "yes" "no"];
        default = "auto";
      };
      costs = lib.mkOption {
        description = ''
          Known costs to specified peers

          The cost of a tunnel will be the highest of the
          specified costs between the two nodes, and defaults to
          20 if neither has specified a cost.
        '';
        type = types.attrsOf types.ints.unsigned;
        default = {};
        example = {
          node-b = 100;
          node-c = 1;
          node-d = 999;
        };
      };
      extraPeers = lib.mkOption {
        description = ''
          List of additional peers to create tunnels to
        '';
        type = types.listOf types.str;
        default = [];
      };
      mtuBytes = lib.mkOption {
        description = ''
          MTU of wireguard interface.
        '';
        type = types.ints.unsigned;
        default = 1420;
      };
    };
  };
  groupType = types.submodule {
    options = {
      hubs = lib.mkOption {
        description = ''
          Nodes to which all nodes in the group should have a tunnel

          Useful for regional hub-and-spokes networks.
        '';
        type = types.listOf types.str;
        default = [];
      };
      fullMesh = lib.mkOption {
        description = ''
          Whether to enable full mesh for all nodes in the group
        '';
        type = types.bool;
        default = false;
      };
    };
  };
  tunnelType = types.submodule {
    options = {
      peer = lib.mkOption {
        description = ''
          Name of the node
        '';
        type = types.str;
      };
      endpoint = lib.mkOption {
        description = ''
          Endpoint
        '';
        type = types.nullOr types.str;
      };
      publicKey = lib.mkOption {
        description = ''
          Peer public key
        '';
        type = types.str;
      };
      listenPort = lib.mkOption {
        description = ''
          Port to listen on
        '';
        type = types.ints.unsigned;
      };
      cost = lib.mkOption {
        description = ''
          Cost
        '';
        type = types.ints.unsigned;
        default = 20;
      };
      persistentKeepalive = lib.mkOption {
        description = ''
          Whether to enable persistent keep-alive
        '';
        type = types.bool;
        default = false;
      };
      linkLocalId = lib.mkOption {
        description = ''
          Link local identifier
        '';
        type = types.ints.unsigned;
      };
      myId = lib.mkOption {
        description = ''
          Link local identifier -- my id
        '';
        type = types.ints.unsigned;
      };
      peerId = lib.mkOption {
        description = ''
          Link local identifier -- peer id
        '';
        type = types.ints.unsigned;
      };
      mtuBytes = lib.mkOption {
        description = ''
          MTU for this WG interface
        '';
        type = types.ints.unsigned;
      };
    };
  };
  endpointOverrideType = types.submodule {
    options = {
      src = lib.mkOption {
        description = ''
          From this node -- node name
        '';
        type = types.nullOr types.str;
        default = null;
      };
      dst = lib.mkOption {
        description = ''
          To this node -- node name
        '';
        type = types.nullOr types.str;
        default = null;
      };
      endpoint = lib.mkOption {
        description = ''
          Static endpoint
          null means don't override.
          empty string means no endpoint.
        '';
        type = endpointType;
        default = {};
      };
      connectPort = lib.mkOption {
        description = ''
          Which port to use for endpoint.
          null means don't override.
        '';
        type = types.nullOr types.port;
        default = null;
      };
      listenPort = lib.mkOption {
        description = ''
          Which port to use for listening.
          null means don't override.
        '';
        type = types.nullOr types.port;
        default = null;
      };
    };
  };
in {
  imports = [
    ./gentunnels.nix
    ./wireguard.nix
  ];

  options = {
    jq-networks.supplemental.ngtun = {
      enable = lib.mkOption {
        description = ''
          Participate in the mesh

          The `group` configurations must be identical on
          all nodes, as the tunnels are created "from their
          perspective."
        '';
        type = types.bool;
        default = true;
      };

      global = lib.mkOption {
        description = ''
          Global options
        '';
        type = globalType;
        default = {};
      };
      node = lib.mkOption {
        description = ''
          Node options
        '';
        type = nodeType;
        default = {};
      };
      groups = lib.mkOption {
        description = ''
          Groups

          Must be identical across all nodes. Specify
          this in the common configurations.
        '';
        type = types.attrsOf groupType;
        default = {};
      };

      # Internal options
      generatedTunnels = lib.mkOption {
        description = ''
          (Internal option)

          Generated tunnels

          This shouldn't be manually set.
        '';
        type = types.attrsOf tunnelType;
        default = {};
      };
      defaultGroupConfig = lib.mkOption {
        description = ''
          (Internal option)
        '';
        type = groupType;
        default = {};
      };

      endpointOverrides = lib.mkOption {
        description = ''
          Override some connections globally.
        '';
        type = types.listOf endpointOverrideType;
        default = [];
      };

      debug = lib.mkOption {
        type = types.unspecified;
      };
    };
  };
}
