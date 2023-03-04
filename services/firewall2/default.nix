{ config, pkgs, lib, ... }:
let
  compositeType = with lib.types; nullOr (either
    (either str ints.unsigned)
    (listOf (either str ints.unsigned)));

  mkComposite = description: mkOption {
    inherit description;
    default = null;
    type = compositeType;
  };

  portForwardType = types.submodule {
    options = {
      srcPort = mkComposite "Inbound dst port, use 111-222 for ranges";
      dstPort = mkComposite "Outbound dst port, use 111-222 for ranges";
      interface = mkComposite "Inbound interface";
      dstIp = mkComposite "Forward to which host";
      protocol = mkComposite "What protocol to forward";
    };
  };

  cfg = config.jq-networks.services.firewall2;
in
{
  options.jq-networks.services.firewall2 = {
    enable = mkEnableOption "Enable nftables.";

    wanInterface = mkOption {
      type = types.str;
      default = "";
      description = "Add nat to outbound traffic.";
    };

    tcpOpenPorts = mkOption {
      type = types.listOf types.ports;
      default = [ ];
      description = "TCP Ports to open on INPUT";
    };

    udpOpenPorts = mkOption {
      type = types.listOf types.ports;
      default = [ ];
      description = "UDP Ports to open on INPUT";
    };

    portForwards = mkOption {
      type = types.listOf portForwardType;
      default = [ ];
      example = [
        {
          srcPort = "45550-45570";
          dstPort = "45550-45570";
          interface = "wan";
          dstIp = "192.168.1.101";
          protocol = [ "tcp" "udp" ];
        }
      ];
    };

  };
  config.jq-networks.supplemental.nftables = {
    enable = true;
    config = {
      filter = {
        family = "inet";
        sets = {
          allow_tcp = {
            type = "inet_service";
            flags = "interval";
            elements = cfg.tcpOpenPorts;
          };
          allow_udp = {
            type = "inet_service";
            flags = "interval";
            elements = udpOpenPorts;
          };
        };

        chains = {
          # replacement of iptables table Filter chain OUTPUT
          output = {
            type = "filter";
            hook = "output";
            priority = "100";
            policy = "accept";
            rules = [ ];
          };

          # replacement of iptables table Filter chain INPUT
          input = {
            type = "filter";
            hook = "input";
            priority = "filter";
            policy = "drop";
            rules = [
              {
                iifname = "lo";
                action = "accept";
              }
              {
                "ip protocol" = "icmp";
                "icmp type" = "echo-request";
                action = "accept";
              }
              # {
              #   iifname = "t-*";
              #   counter = "";
              #   action = "accept";
              # }
              {
                "tcp dport" = "@allow_tcp";
                action = "accept";
              }
              {
                "udp dport" = "@allow_udp";
                action = "accept";
              }
              {
                "ct state" = [ "related" "established" ];
                counter = true;
                action = "accept";
              }
            ];
          };

          # replacement of iptables table Filter chain FORWARD
          forward = {
            type = "filter";
            hook = "forward";
            priority = "filter";
            policy = "drop";
            rules = [
              {
                oifname = cfg.wanInterface;
                "tcp flags" = "syn";
                "tcp option" = "maxseg size";
                action = "set rt mtu";
              }
              # {
              #   iifname = "t-*";
              #   action = "accept";
              #   comment = "Allow wireguard outbound";
              # }
              {
                "ct state" = [ "related" "established" ];
                counter = true;
                action = "accept";
                comment = "Allow established connections";
              }
            ];
          };
        };
      };
    };
  };
}
