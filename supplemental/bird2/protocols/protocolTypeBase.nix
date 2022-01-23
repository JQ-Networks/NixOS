{ lib, ... }:
with lib;
with builtins;
let channelType = import ./channelType.nix {inherit lib;};
in {
  disabled = mkOption {
    type = types.nullOr types.bool;
    description = ''
      Disables the protocol. You can change the disable/enable status from the
      command line interface without needing to touch the configuration.
      Disabled protocols are not activated. Default: protocol is enabled.
    '';
    default = null;
  };
  debug = mkOption {
    type = types.nullOr types.str;
    example = "all";
    description = ''
      all|off|{ states|routes|filters|interfaces|events|packets [, ...] }

      Set protocol debugging options. If asked, each protocol is capable of
      writing trace messages about its work to the log (with category
      <code>trace</code>). You can either request printing of <code>all</code> trace messages
      or only of the types selected: <code>states</code> for protocol state changes
      (protocol going up, down, starting, stopping etc.), <code>routes</code> for
      routes exchanged with the routing table, <code>filters</code> for details on
      route filtering, <code>interfaces</code> for interface change events sent to the
      protocol, <code>events</code> for events internal to the protocol and <code>packets</code>
      for packets sent and received by the protocol. Default: off.
    '';
    default = null;
  };

  mrtdump = mkOption {
    type = types.nullOr types.str;
    description = ''
      all|off|{ states|messages [, ...] }

      Set protocol MRTdump flags. MRTdump is a standard binary format for
      logging information from routing protocols and daemons. These flags
      control what kind of information is logged from the protocol to the
      MRTdump file (which must be specified by global <code>mrtdump</code> option, see
      the previous section). Although these flags are similar to flags of
      <code>debug</code> option, their meaning is different and protocol-specific. For
      BGP protocol, <code>states</code> logs BGP state changes and <code>messages</code> logs
      received BGP messages. Other protocols does not support MRTdump yet.
    '';
    default = null;
  };
  routerId = mkOption {
    type = types.nullOr types.str;
    description = ''
      This option can be used to override global router id for a given
      protocol. Default: uses global router id.
    '';
    default = null;
  };
  description = mkOption {
    type = types.nullOr types.str;
    description = ''
      This is an optional description of the protocol. It is displayed as a
      part of the output of 'show protocols all' command.
    '';
    default = null;
  };
  vrf = mkOption {
    type = types.nullOr types.str;
    description = ''
      default or "text", value default will not be quoted.

      Associate the protocol with specific VRF. The protocol will be
      restricted to interfaces assigned to the VRF and will use sockets bound
      to the VRF. A corresponding VRF interface must exist on OS level. For
      kernel protocol, an appropriate table still must be explicitly selected
      by <code>table</code> option.

      Note: By selecting <code>default</code>, the protocol is associated with the default
      VRF; i.e., it will be restricted to interfaces not assigned to any
      regular VRF. That is different from not specifying <code>vrf</code> at all, in
      which case the protocol may use any interface regardless of its VRF
      status.
      </p><p>Note that for proper VRF support it is necessary to use Linux kernel
      version at least 4.14, older versions have limited VRF implementation.
      Before Linux kernel 5.0, a socket bound to a port in default VRF collide
      with others in regular VRFs. In BGP, this can be avoided by using
      <a href="?get_doc&amp;v=20&amp;f=bird-6.html#bgp-strict-bind">strict bind</a> option.
      </p><p>
    '';
    default = null;
  };
  
  channels = {
    ipv4 = mkOption {
      type = types.nullOr channelType;
      description = "channel ipv4";
      default = null;
    };
    ipv6 = mkOption {
      type = types.nullOr channelType;
      description = "channel ipv6";
      default = null;
    };
  };
}
