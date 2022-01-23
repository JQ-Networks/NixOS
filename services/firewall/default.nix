{ config, pkgs, lib, ... }:
with lib;
with builtins;
let
  # General Rules: https://gist.github.com/zhaofengli/378f6cddfeaa95ca3e18f7ef8db9ded7
  commonInputPrepend = [
    ''
      mod state state INVALID DROP;
      mod state state (ESTABLISHED RELATED) ACCEPT;
      interface lo ACCEPT;
    ''
  ];
  commonForwardPrepend = [
    # Can't kill invalid since we might only be hearing half of the conversation
    ''
      mod state state (ESTABLISHED RELATED) ACCEPT;
    ''
  ];
  inputRulesFor = proto: [
    # Always allow ssh, or we screwd
    {
      proto = "tcp";
      dport = [
        22 # common ssh
      ];
      action = "ACCEPT";
    }
    # Always allow icmp
    {
      proto = if proto == "ipv6" then "icmpv6" else "icmp";
      action = "ACCEPT";
    }
    # Always allow internal wg
    {
      proto = [ "tcp" "udp" ];
      interface =
        lib.attrNames config.jq-networks.supplemental.ngtun.generatedTunnels;
    }
  ] ++ (
    let
      extraInterfacesAllow = filter (x: x != "") (unique ([ cfg.lanInterface ] ++ cfg.extraInterfacesAllow));
    in
      if (extraInterfacesAllow != []) then [
        {
          interface = extraInterfacesAllow;
          action = "ACCEPT";
        }
      ] else []
  );
  cfg = config.jq-networks.services.firewall;
in
{
  imports = [ ./portForward.nix ];
  options.jq-networks.services.firewall = {
    enable = mkEnableOption "Enable FERM";
    wanInterface = mkOption {
      type = types.str;
      default = "";
      description = "Enable mss clamping and nat";
    };
    udpRelay = mkEnableOption ''
      Enable udp relay.
      UDP relay requires lanSubnet, lanSubnetBroadcast, lanInterface,
      broadcastInterface and broadcastAddress
    '';
    lanSubnet = mkOption {
      type = types.str;
      example = "192.168.1.0/24";
      description = "For UDP broadcast relay";
      default = "";
    };
    lanSubnetBroadcast = mkOption {
      type = types.str;
      example = "192.168.1.255";
      description = "For UDP broadcast relay";
      default = "";
    };
    lanInterface = mkOption {
      type = types.str;
      example = "br-lan";
      description = "For UDP broadcast relay";
      default = "";
    };
    broadcastInterface = mkOption {
      type = types.str;
      example = "vxlan";
      description = "For UDP broadcast relay";
      default = "";
    };
    broadcastAddress = mkOption {
      type = types.str;
      example = "192.168.1.255";
      description = "For UDP broadcast relay";
      default = "";
    };
    extraInterfacesAllow = mkOption {
      type = types.listOf types.str;
      example = [ "br-lan" ];
      description = "Allow input from these interfaces";
      default = [];
    };
  };
  config.jq-networks.supplemental.firewall = mkIf cfg.enable {
    # INPUT
    ip.filter.chains.input = {
      policy = "DROP";
      prepends = commonInputPrepend;
      rules = inputRulesFor "ipv4";
    };
    ip6.filter.chains.input = {
      policy = "DROP";
      prepends = commonInputPrepend;
      rules = inputRulesFor "ipv6";
    };

    # FORWARD
    # This is much more complicated so let's leave it to
    # the host configs
    ip.filter.chains.forward = {
      prepends = commonForwardPrepend;
      rules = [
        {
          # t-+ is wildcard for wireguard
          outerface = filter (x: x != "") [ "t-+" cfg.wanInterface ];
          proto = "tcp";
          extraFilters = "tcp-flags (SYN RST) SYN";
          action = "TCPMSS";
          args = "clamp-mss-to-pmtu";
        }
      ];
    };
    ip6.filter.chains.forward = { prepends = commonForwardPrepend; };
    # ipv4 MASQUERADE
    ip.nat.chains.postrouting.rules = mkIf (cfg.wanInterface != "") [
      {
        # saddr = "192.168.241.0/24";
        outerface = cfg.wanInterface;
        action = "MASQUERADE";
      }
    ];
    ip.mangle.chains.input.rules = mkIf cfg.udpRelay [
      {
        interface = cfg.lanInterface;
        proto = "udp";
        saddr = cfg.lanSubnet;
        daddr = "255.255.255.255";
        action = "TEE";
        args = "gateway ${cfg.broadcastAddress}"; # tinc
      }
      {
        interface = cfg.broadcastInterface;
        proto = "udp";
        saddr = "! ${cfg.lanSubnet}";
        daddr = "255.255.255.255";
        action = "TEE";
        args = "gateway ${cfg.lanSubnetBroadcast}";
      }
    ];
  };
}
