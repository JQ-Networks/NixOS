{ config, pkgs, lib, ... }:
let
  defaultTCPOpenPorts = [52222 5201];
  defaultUDPOpenPorts = [];
in
{
  jq-networks.supplemental.nftables = {
    config = {
      filter = {
        family = "inet";
        sets = {
          allow_tcp = {
            type = "inet_service";
            flags = "interval";
            elements = defaultTCPOpenPorts;
            extraConfigs = "";
          };
          allow_udp = {
            type = "inet_service";
            flags = "interval";
            elements = defaultUDPOpenPorts;
            extraConfigs = "";
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
              {
                iifname = "t-*";
                counter = "";
                action = "accept";
              }
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
                counter = "";
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
                "tcp flags" = "syn";
                "tcp option" = "maxseg size";
                action = "set rt mtu";
              }
              {
                iifname = "t-*";
                action = "accept";
                comment = "Allow wireguard outbound";
              }
              {
                "ct state" = [ "related" "established" ];
                counter = "";
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
