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
  ts = cfg.tailscale;
  isV6 = p: lib.hasInfix ":" p;
  tsV4 = filter (p: !isV6 p) ts.prefixes;
  tsV6 = filter isV6 ts.prefixes;
  # tailscaled's own anti-spoof rule, but only for the tailnet's real prefixes.
  # tailscaled hardcodes 100.64.0.0/10, which also covers our own overlay
  # (100.64.101.x on lo, 100.64.102.x on tinc) and silently drops it.
  tsAntiSpoof = optionals ts.enable [
    {
      iifname = "!= ${ts.interface}";
      "ip saddr" = tsV4;
      counter = true;
      action = "drop";
      comment = "tailnet source on non-tailscale interface";
    }
    {
      iifname = "!= ${ts.interface}";
      "ip6 saddr" = tsV6;
      counter = true;
      action = "drop";
      comment = "tailnet source on non-tailscale interface";
    }
  ];
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
    tailscale = {
      enable = mkEnableOption ''
        owning tailscale's netfilter rules here. tailscaled is switched to
        --netfilter-mode=off and its rules are reproduced in this table, with the
        anti-spoof drop narrowed to `prefixes` instead of all of 100.64.0.0/10
      '';
      interface = mkOption {
        type = types.str;
        default = config.services.tailscale.interfaceName;
        description = "Tailscale interface.";
      };
      port = mkOption {
        type = types.port;
        default = config.services.tailscale.port;
        description = "tailscaled's WireGuard UDP port, opened for direct peer connections.";
      };
      prefixes = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "100.68.0.0/16" "fd7a:115c:a1e0:2333::/64" ];
        description = "Tailnet address ranges (the control server's IP prefixes). Packets from these are only accepted on `interface`.";
      };
    };
  };
  config.services.tailscale.extraSetFlags = mkIf (cfg.enable && ts.enable) [ "--netfilter-mode=off" ];
  config.systemd.services.reload-podman-firewall = mkIf (config.virtualisation.podman.enable && cfg.enable) {
    description = "nftables firewall";
    after = [ "nftables.service" ];
    bindsTo = [ "nftables.service" ]; # Only starts if nftables exits with success
    wantedBy = [ "nftables.service" ]; # Creates a Wants dependency in service1
    partOf = [ "nftables.service" ]; # Propagates restart from nftables
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network reload --all";
    };
  };
  config.assertions = mkIf cfg.enable [
    {
      assertion = !ts.enable || ts.prefixes != [ ];
      message = "firewall2.tailscale.prefixes must list the tailnet's prefixes.";
    }
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
              ] ++ tsAntiSpoof ++ [
                {
                  "udp dport" = if ts.enable then ts.port else null;
                  action = "accept";
                  comment = "tailscale direct connections";
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
              ] ++ tsAntiSpoof ++ [
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
