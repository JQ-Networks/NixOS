{ config, pkgs, lib, ... }:
with lib;
let
    compositeType = with types; nullOr (either
    (oneOf [ str ints.unsigned bool ])
    (listOf (oneOf [ str ints.unsigned bool ])));

  mkComposite = description: mkOption {
    inherit description;
    default = null;
    type = compositeType;
  };
  cfg = config.jq-networks.services.firewall2;
in
{
  # simplified to just a set of rules. No more templates.
  options.jq-networks.services.firewall2 = {
    enable = mkEnableOption "Enable nftables default rules.";
    tcpOpenPorts = mkComposite "TCP Ports to open on INPUT";
    udpOpenPorts = mkComposite "UDP Ports to open on INPUT";
    trustedInterfaces = mkComposite "Allow all inbound from these interfaces.";
    wanInterface = mkOption {
      type = types.str;
      default = "";
      description = "Add nat to outbound traffic.";
    };
  };
  config.systemd.services.reload-podman-firewall = mkIf (config.virtualisation.podman.enable && cfg.enable) {
    description = "nftables firewall";
    after = [ "nftables.service" ];
    bindsTo = [ "nftables.service" ]; # Only starts if nftables exits with success
    wantedBy = [ "nftables.service" ]; # Creates a Wants dependency in service1
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network reload --all";
    };
  };
  config.assertions = mkIf cfg.enable [
    {
      assertion = (config.services.ferm.enable == false);
      message = "Ferm is not disable!";
    }
  ];
  config.jq-networks.supplemental.nftables =
    mkIf cfg.enable {
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
              elements = cfg.udpOpenPorts;
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
                  "ip6 nexthdr" = "icmpv6";
                  action = "accept";
                }
                {
                  "ct state" = [ "related" "established" ];
                  counter = true;
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
                {
                  iifname = cfg.trustedInterfaces;
                  action = "accept";
                  comment = "Allow wireguard outbound";
                }
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
