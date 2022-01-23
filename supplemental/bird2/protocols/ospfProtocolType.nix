{ lib, ... }:
with lib;
with builtins;
let
  base = import ./protocolTypeBase.nix { inherit lib; };

  interfaceType = types.submodule {
    options = {
      interfaceInstance = mkOption {
        type = types.nullOr types.int;
        description = "Interface ID";
        default = null;
      };

      cost = mkOption {
        type = types.nullOr types.int;
        description = ''
          Specifies output cost (metric) of an interface. Default value is 10.
        '';
        default = null;
      };
      stub = mkOption {
        type = types.nullOr types.bool;
        description = ''
          If set to interface it does not listen to any packet and does not send
          any hello. Default value is no.
        '';
        default = null;
      };
      hello = mkOption {
        type = types.nullOr types.int;
        description = ''
          Specifies interval in seconds between sending of Hello messages. Beware,
          all routers on the same network need to have the same hello interval.
          Default value is 10.
        '';
        default = null;
      };
      poll = mkOption {
        type = types.nullOr types.int;
        description = ''
          Specifies interval in seconds between sending of Hello messages for some
          neighbors on NBMA network. Default value is 20.
        '';
        default = null;
      };
      retransmit = mkOption {
        type = types.nullOr types.int;
        description = ''
          Specifies interval in seconds between retransmissions of unacknowledged
          updates. Default value is 5.
        '';
        default = null;
      };
      transmitDelay = mkOption {
        type = types.nullOr types.int;
        description = ''
          Specifies estimated transmission delay of link state updates send over
          the interface. The value is added to LSA age of LSAs propagated through
          it. Default value is 1.
        '';
        default = null;
      };
      priority = mkOption {
        type = types.nullOr types.int;
        description = ''
          On every multiple access network (e.g., the Ethernet) Designated Router
          and Backup Designated router are elected. These routers have some special
          functions in the flooding process. Higher priority increases preferences
          in this election. Routers with priority 0 are not eligible. Default
          value is 1.
        '';
        default = null;
      };
      wait = mkOption {
        type = types.nullOr types.int;
        description = ''
          After start, router waits for the specified number of seconds between
          starting election and building adjacency. Default value is 4*<em>hello</em>.
        '';
        default = null;
      };
      deadCount = mkOption {
        type = types.nullOr types.int;
        description = ''
          When the router does not receive any messages from a neighbor in
          <em>dead count</em>*<em>hello</em> seconds, it will consider the neighbor down.
        '';
        default = null;
      };
      dead = mkOption {
        type = types.nullOr types.int;
        description = ''
          When the router does not receive any messages from a neighbor in
          <em>dead</em> seconds, it will consider the neighbor down. If both directives
          <code>dead count</code> and <code>dead</code> are used, <code>dead</code> has precedence.
        '';
        default = null;
      };
      secondary = mkOption {
        type = types.nullOr types.bool;
        description = ''
          Usually, if an export filter rejects a selected route, no other route is 
          propagated for that network. This option allows to try the next route in 
          order until one that is accepted is found or all routes for that network 
          are rejected. This can be used for route servers that need to propagate 
          different tables to each client but do not want to have these tables explicitly 
          (to conserve memory). This option requires that the connected routing table is sorted. 
          Default: off.
        '';
        default = null;
      };
      rxBuffer = mkOption {
        type = types.nullOr
          (types.either types.int (types.enum [ "normal" "large" ]));
        description = ''
          This option allows to specify the size of buffers used for packet
          processing. The buffer size should be bigger than maximal size of any
          packets. By default, buffers are dynamically resized as needed, but a
          fixed value could be specified. Value <code>large</code> means maximal allowed
          packet size - 65535.
        '';
        default = null;
      };
      txLength = mkOption {
        type = types.nullOr types.int;
        description = ''
          Transmitted OSPF messages that contain large amount of information are
          segmented to separate OSPF packets to avoid IP fragmentation. This
          option specifies the soft ceiling for the length of generated OSPF
          packets. Default value is the MTU of the network interface. Note that
          larger OSPF packets may still be generated if underlying OSPF messages
          cannot be splitted (e.g. when one large LSA is propagated).
        '';
        default = null;
      };
      interfaceType = mkOption {
        type = types.nullOr (types.enum [
          "broadcast"
          "bcast"
          "pointopoint"
          "ptp"
          "nonbroadcast"
          "nbma"
          "pointomultipoint"
          "ptmp"
        ]);
        description = ''
          original name is type
        '';
        default = null;
      };
      linkLsaSuppression = mkOption {
        type = types.nullOr types.bool;
        description = ''
          In OSPFv3, link LSAs are generated for each link, announcing link-local
          IPv6 address of the router to its local neighbors. These are useless on
          PtP or PtMP networks and this option allows to suppress the link LSA
          origination for such interfaces. The option is ignored on other than PtP
          or PtMP interfaces. Default value is no.
        '';
        default = null;
      };
      strictNonbroadcast = mkOption {
        type = types.nullOr types.bool;
        description = ''
          If set, don't send hello to any undefined neighbor. This switch is
          ignored on other than NBMA or PtMP interfaces. Default value is no.
        '';
        default = null;
      };
      realBroadcast = mkOption {
        type = types.nullOr types.bool;
        description = ''
          In <code>type broadcast</code> or <code>type ptp</code> network configuration, OSPF
          packets are sent as IP multicast packets. This option changes the
          behavior to using old-fashioned IP broadcast packets. This may be useful
          as a workaround if IP multicast for some reason does not work or does
          not work reliably. This is a non-standard option and probably is not
          interoperable with other OSPF implementations. Default value is no.
        '';
        default = null;
      };
      ptpNetmask = mkOption {
        type = types.nullOr types.bool;
        description = ''
          In <code>type ptp</code> network configurations, OSPFv2 implementations should
          ignore received netmask field in hello packets and should send hello
          packets with zero netmask field on unnumbered PtP links. But some OSPFv2
          implementations perform netmask checking even for PtP links. This option
          specifies whether real netmask will be used in hello packets on <code>type
          ptp</code> interfaces. You should ignore this option unless you meet some
          compatibility problems related to this issue. Default value is no for
          unnumbered PtP links, yes otherwise.
        '';
        default = null;
      };
      checkLink = mkOption {
        type = types.nullOr types.bool;
        description = ''
          If set, a hardware link state (reported by OS) is taken into consideration.
          When a link disappears (e.g. an ethernet cable is unplugged), neighbors
          are immediately considered unreachable and only the address of the iface
          (instead of whole network prefix) is propagated. It is possible that
          some hardware drivers or platforms do not implement this feature.
          Default value is yes.
        '';
        default = null;
      };
      bfd = mkOption {
        type = types.nullOr types.bool;
        description = ''
          OSPF could use BFD protocol as an advisory mechanism for neighbor
          liveness and failure detection. If enabled, BIRD setups a BFD session
          for each OSPF neighbor and tracks its liveness by it. This has an
          advantage of an order of magnitude lower detection times in case of
          failure. Note that BFD protocol also has to be configured, see
          <a href="?get_doc&amp;v=20&amp;f=bird-6.html#bfd">BFD</a> section for details. Default value is no.
        '';
        default = null;
      };
      ttlSecurity = mkOption {
        type =
          types.nullOr (types.either types.bool (types.enum [ "tx only" ]));
        description = ''
          TTL security is a feature that protects routing protocols from remote 
          spoofed packets by using TTL 255 instead of TTL 1 for protocol packets 
          destined to neighbors. Because TTL is decremented when packets are 
          forwarded, it is non-trivial to spoof packets with TTL 255 from remote 
          locations. Note that this option would interfere with OSPF virtual links.

          If this option is enabled, the router will send OSPF packets with 
          TTL 255 and drop received packets with TTL less than 255. If this 
          option si set to tx only, TTL 255 is used for sent packets, but 
          is not checked for received packets. Default value is no.
        '';
        default = null;
      };
      txClass = mkOption {
        type = types.nullOr types.int;
        description = ''
          These options specify the ToS/DiffServ/Traffic class/Priority of the 
          outgoing OSPF packets. See tx class common option for detailed description.
        '';
        default = null;
      };
      txDscp = mkOption {
        type = types.nullOr types.int;
        description = ''
          These options specify the ToS/DiffServ/Traffic class/Priority of the 
          outgoing OSPF packets. See tx class common option for detailed description.
        '';
        default = null;
      };
      txPriority = mkOption {
        type = types.nullOr types.int;
        description = ''
          These options specify the ToS/DiffServ/Traffic class/Priority of the 
          outgoing OSPF packets. See tx class common option for detailed description.
        '';
        default = null;
      };

      ecmpWeight = mkOption {
        type = types.nullOr types.int;
        description = ''
          When ECMP (multipath) routes are allowed, this value specifies a
          relative weight used for nexthops going through the iface. Allowed
          values are 1-256. Default value is 1.
        '';
        default = null;
      };
      authentication = mkOption {
        type = types.nullOr (types.enum [ "none" "simple" "cryptographic" ]);
        description = ''
          None: No passwords are sent in OSPF packets. This is the default value.
          Simple: Every packet carries 8 bytes of password. Received packets lacking this
          password are ignored. This authentication mechanism is very weak.
          This option is not available in OSPFv3.
          Cryptographic: An authentication code is appended to every packet. The specific
          cryptographic algorithm is selected by option <code>algorithm</code> for each
          key. The default cryptographic algorithm for OSPFv2 keys is Keyed-MD5
          and for OSPFv3 keys is HMAC-SHA-256. Passwords are not sent open via
          network, so this mechanism is quite secure. Packets can still be read by
          an attacker.
        '';
        default = null;
      };
      password = mkOption {
        type = types.nullOr types.str;
        description = ''
          Specifies a password used for authentication. See
          <a href="?get_doc&amp;v=20&amp;f=bird-3.html#proto-pass">password</a> common option for detailed
          description.
        '';
        default = null;
      };

      passwordSection = mkOption {
        type = types.nullOr types.lines;
        description = ''
          config for password
        '';
        example = ''
          id <num>;
          generate from "<date>";
          generate to "<date>";
          accept from "<date>";
          accept to "<date>";
          from "<date>";
          to "<date>";
          algorithm ( keyed md5 | keyed sha1 | hmac sha1 | hmac sha256 | hmac sha384 | hmac sha512 );
        '';
        default = null;
      };
      neighbors = mkOption {
        type = types.nullOr types.lines;
        description = ''
          A set of neighbors to which Hello messages on NBMA or PtMP networks are
          to be sent. For NBMA networks, some of them could be marked as eligible.
          In OSPFv3, link-local addresses should be used, using global ones is
          possible, but it is nonstandard and might be problematic. And definitely,
          link-local and global addresses should not be mixed.
        '';
        default = null;
      };

    };
  };

  virtualLinkType = types.submodule {
    options = {
      virtualLinkInstance = mkOption {
        type = types.nullOr types.int;
        description = "Virtual Link ID";
        default = null;
      };
      hello = mkOption {
        type = types.nullOr types.int;
        description = ''
          Specifies interval in seconds between sending of Hello messages. Beware,
          all routers on the same network need to have the same hello interval.
          Default value is 10.
        '';
        default = null;
      };
      retransmit = mkOption {
        type = types.nullOr types.int;
        description = ''
          Specifies interval in seconds between retransmissions of unacknowledged
          updates. Default value is 5.
        '';
        default = null;
      };
      wait = mkOption {
        type = types.nullOr types.int;
        description = ''
          After start, router waits for the specified number of seconds between
          starting election and building adjacency. Default value is 4*<em>hello</em>.
        '';
        default = null;
      };
      deadCount = mkOption {
        type = types.nullOr types.int;
        description = ''
          When the router does not receive any messages from a neighbor in
          <em>dead count</em>*<em>hello</em> seconds, it will consider the neighbor down.
        '';
        default = null;
      };
      dead = mkOption {
        type = types.nullOr types.int;
        description = ''
          When the router does not receive any messages from a neighbor in
          <em>dead</em> seconds, it will consider the neighbor down. If both directives
          <code>dead count</code> and <code>dead</code> are used, <code>dead</code> has precedence.
        '';
        default = null;
      };
      authentication = mkOption {
        type = types.nullOr (types.enum [ "none" "simple" "cryptographic" ]);
        description = ''
          None: No passwords are sent in OSPF packets. This is the default value.
          Simple: Every packet carries 8 bytes of password. Received packets lacking this
          password are ignored. This authentication mechanism is very weak.
          This option is not available in OSPFv3.
          Cryptographic: An authentication code is appended to every packet. The specific
          cryptographic algorithm is selected by option <code>algorithm</code> for each
          key. The default cryptographic algorithm for OSPFv2 keys is Keyed-MD5
          and for OSPFv3 keys is HMAC-SHA-256. Passwords are not sent open via
          network, so this mechanism is quite secure. Packets can still be read by
          an attacker.
        '';
        default = null;
      };
      password = mkOption {
        type = types.nullOr types.str;
        description = ''
          Specifies a password used for authentication. See
          <a href="?get_doc&amp;v=20&amp;f=bird-3.html#proto-pass">password</a> common option for detailed
          description.
        '';
        default = null;
      };

      passwordSection = mkOption {
        type = types.nullOr types.lines;
        description = ''
          config for password
        '';
        example = ''
          id <num>;
          generate from "<date>";
          generate to "<date>";
          accept from "<date>";
          accept to "<date>";
          from "<date>";
          to "<date>";
          algorithm ( keyed md5 | keyed sha1 | hmac sha1 | hmac sha256 | hmac sha384 | hmac sha512 );
        '';
        default = null;
      };
    };
  };

  ospfAreaType = types.submodule {
    options = {
      stub = mkOption {
        type = types.nullOr types.bool;
        description = ''
          This option configures the area to be a stub area. External routes are
          not flooded into stub areas. Also summary LSAs can be limited in stub
          areas (see option <code>summary</code>). By default, the area is not a stub
          area.
        '';
        default = null;
      };
      nssa = mkOption {
        type = types.nullOr types.bool;
        description = ''
          This option configures the area to be a NSSA (Not-So-Stubby Area). NSSA
          is a variant of a stub area which allows a limited way of external route
          propagation. Global external routes are not propagated into a NSSA, but
          an external route can be imported into NSSA as a (area-wide) NSSA-LSA
          (and possibly translated and/or aggregated on area boundary). By
          default, the area is not NSSA.
        '';
        default = null;
      };
      summary = mkOption {
        type = types.nullOr types.bool;
        description = ''
          This option controls propagation of summary LSAs into stub or NSSA
          areas. If enabled, summary LSAs are propagated as usual, otherwise just
          the default summary route (0.0.0.0/0) is propagated (this is sometimes
          called totally stubby area). If a stub area has more area boundary
          routers, propagating summary LSAs could lead to more efficient routing
          at the cost of larger link state database. Default value is no.
        '';
        default = null;
      };
      defaultNssa = mkOption {
        type = types.nullOr types.bool;
        description = ''
          When <code>summary</code> option is enabled, default summary route is no longer
          propagated to the NSSA. In that case, this option allows to originate
          default route as NSSA-LSA to the NSSA. Default value is no.
        '';
        default = null;
      };
      defaultCost = mkOption {
        type = types.nullOr types.int;
        description = ''
          This option controls the cost of a default route propagated to stub and
          NSSA areas. Default value is 1000.
        '';
        default = null;
      };
      defaultCost2 = mkOption {
        type = types.nullOr types.int;
        description = ''
          When a default route is originated as NSSA-LSA, its cost can use either
          type 1 or type 2 metric. This option allows to specify the cost of a
          default route in type 2 metric. By default, type 1 metric (option
          <code>default cost</code>) is used.
        '';
        default = null;
      };
      translator = mkOption {
        type = types.nullOr types.bool;
        description = ''
          This option controls translation of NSSA-LSAs into external LSAs. By
          default, one translator per NSSA is automatically elected from area
          boundary routers. If enabled, this area boundary router would
          unconditionally translate all NSSA-LSAs regardless of translator
          election. Default value is no.
        '';
        default = null;
      };
      translatorStability = mkOption {
        type = types.nullOr types.int;
        description = ''
          This option controls the translator stability interval (in seconds).
          When the new translator is elected, the old one keeps translating until
          the interval is over. Default value is 40.
        '';
        default = null;
      };
      networks = mkOption {
        type = types.nullOr types.lines;
        description = ''
          Definition of area IP ranges. This is used in summary LSA origination.
          Hidden networks are not propagated into other areas.
        '';
        default = null;
      };
      external = mkOption {
        type = types.nullOr types.lines;
        description = ''
          Definition of external area IP ranges for NSSAs. This is used for
          NSSA-LSA translation. Hidden networks are not translated into external
          LSAs. Networks can have configured route tag.
        '';
        default = null;
      };
      stubnet = mkOption {
        type = types.attrsOf types.lines;
        description = ''
          Stub networks are networks that are not transit networks between OSPF
          routers. They are also propagated through an OSPF area as a part of a
          link state database. By default, BIRD generates a stub network record
          for each primary network address on each OSPF interface that does not
          have any OSPF neighbors, and also for each non-primary network address
          on each OSPF interface. This option allows to alter a set of stub
          networks propagated by this router.

          Note: Each instance of this option adds a stub network with given network
          prefix to the set of propagated stub network, unless option <code>hidden</code>
          is used. It also suppresses default stub networks for given network
          prefix. When option <code>summary</code> is used, also default stub networks
          that are subnetworks of given stub network are suppressed. This might be
          used, for example, to aggregate generated stub networks.
        '';
        default = { };
      };

      interface = mkOption {
        type = types.attrsOf interfaceType;
        description = ''
          Defines that the specified interfaces belong to the area being defined.
          See 
          <a href="?get_doc&amp;v=20&amp;f=bird-3.html#proto-iface">interface</a> common option for detailed
          description. In OSPFv2, extended interface clauses are used, because
          each network prefix is handled as a separate virtual interface.

          Note: You can specify alternative instance ID for the interface definition,
          therefore it is possible to have several instances of that interface
          with different options or even in different areas. For OSPFv2, instance
          IDSupport="http://www.rfc-editor.org/info/rfc6549">RFC 6549</a>) and is supposed to be set
          per-protocol. For OSPFv3, it is an integral feature.
        '';
        default = { };
      };

      virtualLink = mkOption {
        type = types.attrsOf virtualLinkType;
        description = ''
          Virtual link to router with the router id. Virtual link acts as a
          point-to-point interface belonging to backbone. The actual area is used
          as a transport area. This item cannot be in the backbone. Like with
          <code>interface</code> option, you could also use several virtual links to one
          destination with different instance IDs.
        '';
        default = { };
      };

    };
  };

in types.submodule {
  options = base // {
    version = mkOption {
      type = types.nullOr (types.enum [ "v2" "v3" ]);
      description = "OSPF version";
      default = null;
    };
    rfc1583compat = mkOption {
      type = types.nullOr types.bool;
      description = ''
        This option controls compatibility of routing table calculation with
        <a href="http://www.rfc-editor.org/info/rfc1583">RFC 1583</a>. Default value is no.
      '';
      default = null;
    };
    rfc5838 = mkOption {
      type = types.nullOr types.bool;
      description = ''
        BasicOSPFv3="http://www.rfc-editor.org/info/rfc5838">RFC 5838</a>
        extension defines support for more address families (IPv4, IPv6, both
        unicast and multicast). The extension is enabled by default, but can be
        disabled if necessary, as it restricts the range of available instance
        IDs. Default value is yes.
      '';
      default = null;
    };
    instanceId = mkOption {
      type = types.nullOr types.int;
      description = ''
        When multiple OSPF protocol instances are active on the same links, they
        should use different instance IDs to distinguish their packets. Although
        it could be done on per-interface basis, it is often preferred to set
        one instance ID to whole OSPF domain/topology (e.g., when multiple
        instances are used to represent separate logical topologies on the same
        physical network). This option specifies the instance ID for all
        interfaces of the OSPF instance, but can be overridden by
        <code>interface</code> option. Default value is 0 unless OSPFv3-AF extended
        addressFamilies="http://www.rfc-editor.org/info/rfc5838">RFC 5838</a> for that case.
      '';
      default = null;
    };
    stubRouter = mkOption {
      type = types.nullOr types.bool;
      description = ''
        This option configures the router to be a stub router, i.e., a router
        that participates in the OSPF topology but does not allow transit
        traffic. In OSPFv2, this is implemented by advertising maximum metric
        for outgoing links. In OSPFv3, the stub router behavior is announced by
        clearingThe="http://www.rfc-editor.org/info/rfc6987">RFC 6987</a> for details.
        Default value is no.
      '';
      default = null;
    };
    tick = mkOption {
      type = types.nullOr types.int;
      description = ''
        The routing table calculation and clean-up of areas' databases is not
        performed when a single link state change arrives. To lower the CPU
        utilization, it's processed later at periodical intervals of <em>num</em>
        seconds. The default value is 1.
      '';
      default = null;
    };
    ecmp = mkOption {
      type = types.nullOr types.bool;
      description = ''
        This option specifies whether OSPF is allowed to generate ECMP
        (equal-cost multipath) routes. Such routes are used when there are
        several directions to the destination, each with the same (computed)
        cost. This option also allows to specify a limit on maximum number of
        nexthops in one route. By default, ECMP is enabled if supported by
        Kernel. Default value of the limit is 16.
      '';
      default = null;
    };
    ecmpLimit = mkOption {
      type = types.nullOr types.int;
      description = "See ecmp";
      default = null;
    };
    mergeExternal = mkOption {
      type = types.nullOr types.bool;
      description = ''
        This option specifies whether OSPF should merge external routes from
        different routers/LSAs for the same destination. When enabled together
        with <code>ecmp</code>, equal-cost external routes will be combined to multipath
        routes in the same way as regular routes. When disabled, external routes
        from different LSAs are treated as separate even if they represents the
        same destination. Default value is no.
      '';
      default = null;
    };
    gracefulRestart = mkOption {
      type = types.nullOr (types.either types.bool (types.enum [ "aware" ]));
      description = ''
        graceful restart switch" "aware

        When an OSPF instance is restarted, neighbors break adjacencies and 
        recalculate their routing tables, which disrupts packet forwarding 
        even when the forwarding plane of the restarting router remains intact. 
        RFC 3623 specifies a graceful restart mechanism to alleviate this issue. 
        For OSPF graceful restart, restarting router originates Grace-LSAs, 
        announcing intent to do graceful restart. Neighbors receiving these 
        LSAs enter helper mode, in which they ignore breakdown of adjacencies, 
        behave as if nothing is happening and keep old routes. When adjacencies 
        are reestablished, the restarting router flushes Grace-LSAs and 
        graceful restart is ended.

        This option controls the graceful restart mechanism. It has three states: 
        Disabled, when no support is provided. Aware, when graceful restart helper 
        mode is supported, but no local graceful restart is allowed 
        (i.e. helper-only role). Enabled, when the full graceful restart 
        support is provided (i.e. both restarting and helper role). 
        Note that proper support for local graceful restart requires 
        also configuration of other protocols. 
        Default: aware.
      '';
      default = null;
    };
    gracefulRestartTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        The restart time is announced in the Grace-LSA and specifies how long
        neighbors should wait for proper end of the graceful restart before
        exiting helper mode prematurely. Default: 120 seconds.
      '';
      default = null;
    };
    area = mkOption {
      type = types.attrsOf ospfAreaType;
      description = ''
        This defines an OSPF area with given area ID (an integer or an IPv4
        address, similarly to a router ID). The most important area is the
        backbone (ID 0) to which every other area must be connected.
      '';
      default = {};
    };

  };
}
