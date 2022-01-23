{ lib, ... }:
with lib;
with builtins;
let base = import ./protocolTypeBase.nix { inherit lib; };
in types.submodule {
  options = base // {
    persist = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Tell BIRD to leave all its routes in the routing tables when it exits
        (instead of cleaning them up).
      '';
      default = null;
    };
    scanTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        Time in seconds between two consecutive scans of the kernel routing
        table.
      '';
      default = null;
    };
    learn = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Enable learning of routes added to the kernel routing tables by other
        routing daemons or by the system administrator. This is possible only on
        systems which support identification of route authorship.
      '';
      default = null;
    };
    kernelTable = mkOption {
      type = types.nullOr types.int;
      description = ''
        Select which kernel table should this particular instance of the Kernel
        protocol work with. Available only on systems supporting multiple
        routing tables.
      '';
      default = null;
    };
    metric = mkOption {
      type = types.nullOr types.int;
      description = ''
        (Linux)
        Use specified value as a kernel metric (priority) for all routes sent to
        the kernel. When multiple routes for the same network are in the kernel
        routing table, the Linux kernel chooses one with lower metric. Also,
        routes with different metrics do not clash with each other, therefore
        using dedicated metric value is a reliable way to avoid overwriting
        routes from other sources (e.g. kernel device routes). Metric 0 has a
        special meaning of undefined metric, in which either OS default is used,
        or per-route metric can be set using <code>krt_metric</code> attribute. Default:
        32.
      '';
      default = null;
    };
    gracefulRestart = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Participate in graceful restart recovery. If this option is enabled and
        a graceful restart recovery is active, the Kernel protocol will defer
        synchronization of routing tables until the end of the recovery. Note
        that import of kernel routes to BIRD is not affected.
      '';
      default = null;
    };
    mergePaths = mkOption {
      type = types.nullOr types.bool;
      description = ''
        merge paths switch [limit number]

        Usually, only best routes are exported to the kernel protocol. With path
        merging enabled, both best routes and equivalent non-best routes are
        merged during export to generate one ECMP (equal-cost multipath) route
        for each network. This is useful e.g. for BGP multipath. Note that best
        routes are still pivotal for route export (responsible for most
        properties of resulting ECMP routes), while exported non-best routes are
        responsible just for additional multipath next hops. This option also
        allows to specify a limit on maximal number of nexthops in one route. By
        default, multipath merging is disabled. If enabled, default value of the
        limit is 16.
      '';
      default = null;
    };

    mergePathsLimit = mkOption {
      type = types.nullOr types.int;
      description = "See mergePaths";
      default = null;
    };
  };
}
