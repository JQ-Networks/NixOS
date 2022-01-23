{ lib, ... }:
with lib;
with builtins;
let base = import ./protocolTypeBase.nix { inherit lib; };
in types.submodule {
  options = base // {
    checkLink = mkOption {
      type = types.nullOr types.bool;
      description = ''
        If set, hardware link states of network interfaces are taken into
        consideration.  When link disappears (e.g. ethernet cable is unplugged),
        static routes directing to that interface are removed. It is possible
        that some hardware drivers or platforms do not implement this feature.
        Default: off.
      '';
      default = null;
    };
    igpTable = mkOption {
      type = types.nullOr types.str;
      description = ''
        Specifies a table that is used for route table lookups of recursive
        routes. Default: the same table as the protocol is connected to.
      '';
      default = null;
    };

    route = mkOption {
      type = types.nullOr types.lines;
      description = ''
        route prefix via ip|"interface" [mpls num[/num[/num[...]]]]
        Next hop routes may bear one or more next hops. Every next hop is preceded by via and configured as shown.

        route prefix recursive ip [mpls num[/num[/num[...]]]]
        Recursive nexthop resolves the given IP in the configured IGP table and uses that route's next hop. The MPLS stacks are concatenated; on top is the IGP's nexthop stack and on bottom is this route's stack.

        route prefix blackhole|unreachable|prohibit
        Special routes specifying to silently drop the packet, return it as unreachable or return it as administratively prohibited. First two targets are also known as drop and reject.

        When the particular destination is not available (the interface is down or the next hop of the route is not a neighbor at the moment), Static just uninstalls the route from the table it is connected to and adds it again as soon as the destination becomes adjacent again.
      '';
      default = null;
    };
    extraConfig = mkOption {
      type = types.nullOr types.lines;
      default = "";
      description = ''
        Other protocol specific config
      '';
    };
  };
}
