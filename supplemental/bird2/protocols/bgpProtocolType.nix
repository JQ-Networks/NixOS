{ lib, ... }:
with lib;
with builtins;
let base = import ./protocolTypeBase.nix { inherit lib; };
in types.submodule {
  options = base // {
    local = mkOption {
      type = types.nullOr types.str;
      description = ''
        [ip] [port number] [as number]

        Define which AS we are part of. (Note that contrary to other IP routers,
        BIRD is able to act as a router located in multiple AS'es simultaneously,
        but in such cases you need to tweak the BGP paths manually in the filters
        to get consistent behavior.) Optional <code>ip</code> argument specifies a source
        address, equivalent to the <code>source address</code> option (see below).
        Optional <code>port</code> argument specifies the local BGP port instead of
        standard port 179. The parameter may be used multiple times with
        different sub-options (e.g., both <code>local 10.0.0.1 as 65000;</code> and
        <code>local 10.0.0.1; local as 65000;</code> are valid). This parameter is
        mandatory.
      '';
      default = null;
    };

    neighbor = mkOption {
      type = types.nullOr types.str;
      description = ''
        [ip | range prefix] [port number] [as number] [internal|external]

        Define neighboring router this instance will be talking to and what AS it is 
        located in. In case the neighbor is in the same AS as we are, we automatically 
        switch to IBGP. Alternatively, it is possible to specify just internal or 
        external instead of AS number, in that case either local AS number, or any 
        external AS number is accepted. Optionally, the remote port may also be 
        specified. Like local parameter, this parameter may also be used multiple 
        times with different sub-options. This parameter is mandatory.

        It is possible to specify network prefix (with range keyword) instead 
        of explicit neighbor IP address. This enables dynamic BGP behavior, 
        where the BGP instance listens on BGP port, but new BGP instances are 
        spawned for incoming BGP connections (if source address matches the 
        network prefix). It is possible to mix regular BGP instances with 
        dynamic BGP instances and have multiple dynamic BGP instances with 
        different ranges.
      '';
      default = null;
    };

    interface = mkOption {
      type = types.listOf types.str;
      description = ''
        Define interface we should use for link-local BGP IPv6 sessions.
        Interface can also be specified as a part of <code>neighbor address</code>
        (e.g., <code>neighbor fe80::1234%eth0 as 65000;</code>). The option may also be
        used for non link-local sessions when it is necessary to explicitly
        specify an interface, but only for direct (not multihop) sessions.
      '';
      default = [];
    };

    direct = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Specify that the neighbor is directly connected. The IP address of the neighbor 
        must be from a directly reachable IP range (i.e. associated with one of your 
        router's interfaces), otherwise the BGP session wouldn't start but it would 
        wait for such interface to appear. The alternative is the multihop option. 
        Default: enabled for eBGP.
      '';
      default = null;
    };

    multihop = mkOption {
      type = types.nullOr (types.either types.bool types.int);
      description = ''
        Configure multihop BGP session to a neighbor that isn't directly
        connected. Accurately, this option should be used if the configured
        neighbor IP address does not match with any local network subnets. Such
        IP address have to be reachable through system routing table. The
        alternative is the <code>direct</code> option. For multihop BGP it is
        recommended to explicitly configure the source address to have it
        stable. Optional <code>number</code> argument can be used to specify the number
        of hops (used for TTL). Note that the number of networks (edges) in a
        path is counted; i.e., if two BGP speakers are separated by one router,
        the number of hops is 2. 
        Default: enabled for iBGP.
      '';
      default = null;
    };
    sourceAddress = mkOption {
      type = types.nullOr types.str;
      description = ''
        Define local address we should use as a source address for the BGP
        session. Default: the address of the local end of the interface our
        neighbor is connected to.
      '';
      default = null;
    };
    dynamicName = mkOption {
      type = types.nullOr types.str;
      description = ''
        Define common prefix of names used for new BGP instances spawned 
        when dynamic BGP behavior is active. Actual names also contain 
        numeric index to distinguish individual instances. 
        Default: "dynbgp".
      '';
      default = null;
    };
    dynamicNameDigits = mkOption {
      type = types.nullOr types.int;
      description = ''
        Define minimum number of digits for index in names of spawned dynamic
        BGP instances. E.g., if set to 2, then the first name would be
        "dynbgp01". 
        Default: 0.
      '';
      default = null;
    };
    strictBind = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Specify whether BGP listening socket should be bound to a specific local
        address (the same as the <code>source address</code>) and associated interface,
        or to all addresses. Binding to a specific address could be useful in
        cases like running multiple BIRD instances on a machine, each using its
        IP address. Note that listening sockets bound to a specific address and
        to all addresses collide, therefore either all BGP protocols (of the
        same address family and using the same local port) should have set
        <code>strict bind</code>, or none of them. 
        Default: disabled.
      '';
      default = null;
    };
    checkLink = mkOption {
      type = types.nullOr types.bool;
      description = ''
        BGP could use hardware link state into consideration.  If enabled,
        BIRD tracks the link state of the associated interface and when link
        disappears (e.g. an ethernet cable is unplugged), the BGP session is
        immediately shut down. Note that this option cannot be used with
        multihop BGP. 
        Default: enabled for direct BGP, disabled otherwise.
      '';
      default = null;
    };
    bfd = mkOption {
      type = types.nullOr (types.either types.bool (types.enum [ "graceful" ]));
      description = ''
        BGP could use BFD protocol as an advisory mechanism for neighbor 
        liveness and failure detection. If enabled, BIRD setups a BFD session 
        for the BGP neighbor and tracks its liveness by it. This has an advantage 
        of an order of magnitude lower detection times in case of failure. When 
        a neighbor failure is detected, the BGP session is restarted. Optionally, 
        it can be configured (by graceful argument) to trigger graceful restart 
        instead of regular restart. Note that BFD protocol also has to be configured, 
        see BFD section for details. 
        Default: disabled.
      '';
      default = null;
    };
    ttlSecurity = mkOption {
      type = types.nullOr types.bool;
      description = ''
        UseGTSM="http://www.rfc-editor.org/info/rfc5082">RFC 5082</a> - the generalized TTL security mechanism). GTSM
        protects against spoofed packets by ignoring received packets with a
        smaller than expected TTL. To work properly, GTSM have to be enabled on
        both sides of a BGP session. If both <code>ttl security</code> and
        <code>multihop</code> options are enabled, <code>multihop</code> option should specify
        proper hop value to compute expected TTL. Kernel support required:
        Linux: 2.6.34+ (IPv4), 2.6.35+ (IPv6), BSD: since long ago, IPv4 only.
        NoteThat="http://www.rfc-editor.org/info/rfc5082">RFC 5082</a> support is
        provided by Linux only. 
        Default: disabled.
      '';
      default = null;
    };
    password = mkOption {
      type = types.nullOr types.str;
      description = ''
        UseThis="http://www.rfc-editor.org/info/rfc2385">RFC 2385</a>). When
        used on BSD systems, see also <code>setkey</code> option below. 
        Default: no authentication.
      '';
      default = null;
    };
    setkey = mkOption {
      type = types.nullOr types.bool;
      description = ''
        On BSD systems, keys for TCP MD5 authentication are stored in the global
        SA/SP database, which can be accessed by external utilities (e.g.
        setkey(8)). BIRD configures security associations in the SA/SP database
        automatically based on <code>password</code> options (see above), this option
        allows to disable automatic updates by BIRD when manual configuration by
        external utilities is preferred. Note that automatic SA/SP database
        updates are currently implemented only for FreeBSD. Passwords have to be
        set manually by an external utility on NetBSD and OpenBSD. 
        Default: enabled (ignored on non-FreeBSD).
      '';
      default = null;
    };
    passive = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Standard BGP behavior is both initiating outgoing connections and
        accepting incoming connections. In passive mode, outgoing connections
        are not initiated. 
        Default: off.
      '';
      default = null;
    };
    confederation = mkOption {
      type = types.nullOr types.int;
      description = ''
        BGPConfederations="http://www.rfc-editor.org/info/rfc5065">RFC 5065</a>) are collections of autonomous
        systems that act as one entity to external systems, represented by one
        confederation identifier (instead of AS numbers). This option allows to
        enable BGP confederation behavior and to specify the local confederation
        identifier. When BGP confederations are used, all BGP speakers that are
        members of the BGP confederation should have the same confederation
        identifier configured. 
        Default: 0 (no confederation).
      '';
      default = null;
    };
    confederationMember = mkOption {
      type = types.nullOr types.bool;
      description = ''
        When BGP confederations are used, this option allows to specify whether
        the BGP neighbor is a member of the same confederation as the local BGP
        speaker. The option is unnecessary (and ignored) for IBGP sessions, as
        the same AS number implies the same confederation. 
        Default: no.
      '';
      default = null;
    };
    rrClient = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Be a route reflector and treat the neighbor as a route reflection
        client. 
        Default: disabled.
      '';
      default = null;
    };
    rrClusterId = mkOption {
      type = types.nullOr types.str;
      description = ''
        Route reflectors use cluster id to avoid route reflection loops. When
        there is one route reflector in a cluster it usually uses its router id
        as a cluster id, but when there are more route reflectors in a cluster,
        these need to be configured (using this option) to use a common cluster
        id. Clients in a cluster need not know their cluster id and this option
        is not allowed for them. 
        Default: the same as router id.
      '';
      default = null;
    };
    rsClient = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Be a route server and treat the neighbor as a route server client.
        A route server is used as a replacement for full mesh EBGP routing in
        Internet exchange points in a similar way to route reflectors used in
        IBGPRouting="http://www.rfc-editor.org/info/rfc1863">RFC 1863</a>, but
        uses ad-hoc implementation, which behaves like plain EBGP but reduces
        modifications to advertised route attributes to be transparent (for
        example does not prepend its AS number to AS PATH attribute and
        keeps MED attribute). 
        Default: disabled.
      '';
      default = null;
    };
    allowBgpLocalPref = mkOption {
      type = types.nullOr types.bool;
      description = ''
        A standard BGP implementation do not send the Local Preference attribute
        to eBGP neighbors and ignore this attribute if received from eBGP
        neighbors, as per <a href="http://www.rfc-editor.org/info/rfc4271">RFC 4271</a>.  When this option is enabled on an
        eBGP session, this attribute will be sent to and accepted from the peer,
        whichIs="http://www.rfc-editor.org/info/rfc7938">RFC 7938</a>.
        The option does not affect iBGP sessions. 
        Default: off.
      '';
      default = null;
    };
    allowLocalAs = mkOption {
      type = types.nullOr (types.either types.bool types.int);
      description = ''
        BGP prevents routing loops by rejecting received routes with the local
        AS number in the AS path. This option allows to loose or disable the
        check. Optional <code>number</code> argument can be used to specify the maximum
        number of local ASNs in the AS path that is allowed for received
        routes. When the option is used without the argument, the check is
        completely disabled and you should ensure loop-free behavior by some
        other means. 
        Default: 0 (no local AS number allowed).
      '';
      default = null;
    };
    enableRouteRefesh = mkOption {
      type = types.nullOr types.bool;
      description = ''
        After the initial route exchange, BGP protocol uses incremental updates
        to keep BGP speakers synchronized. Sometimes (e.g., if BGP speaker
        changes its import filter, or if there is suspicion of inconsistency) it
        is necessary to do a new complete route exchange. BGP protocol extension
        RouteRefresh="http://www.rfc-editor.org/info/rfc2918">RFC 2918</a>) allows BGP speaker to request
        re-advertisement of all routes from its neighbor. BGP protocol
        extensionEnhanced="http://www.rfc-editor.org/info/rfc7313">RFC 7313</a>) specifies explicit
        begin and end for such exchanges, therefore the receiver can remove
        stale routes that were not advertised during the exchange. This option
        specifies whether BIRD advertises these capabilities and supports
        related procedures. Note that even when disabled, BIRD can send route
        refresh requests.  
        Default: on.
      '';
      default = null;
    };
    gracefulRestart = mkOption {
      type = types.nullOr (types.either types.bool (types.enum [ "aware" ]));
      description = ''
        graceful restart switch|aware

        When a BGP speaker restarts or crashes, neighbors will discard all 
        received paths from the speaker, which disrupts packet forwarding 
        even when the forwarding plane of the speaker remains intact. 
        RFC 4724 specifies an optional graceful restart mechanism to 
        alleviate this issue. This option controls the mechanism. It has 
        three states: Disabled, when no support is provided. Aware, when 
        the graceful restart support is announced and the support for 
        restarting neighbors is provided, but no local graceful restart 
        is allowed (i.e. receiving-only role). Enabled, when the full 
        graceful restart support is provided (i.e. both restarting and 
        receiving role). Restarting role could be also configured per-channel. 
        Note that proper support for local graceful restart requires also 
        configuration of other protocols. 
        Default: aware.
      '';
      default = null;
    };
    gracefulRestartTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        The restart time is announced in the BGP graceful restart capability
        and specifies how long the neighbor would wait for the BGP session to
        re-establish after a restart before deleting stale routes. 
        Default: 120 seconds.
      '';
      default = null;
    };
    longLivedGracefulRestart = mkOption {
      type = types.nullOr (types.either types.bool (types.enum [ "aware" ]));
      description = ''
        The long-lived graceful restart is an extension of the traditional 
        BGP graceful restart, where stale routes are kept even after the 
        restart time expires for additional long-lived stale time, but they 
        are marked with the LLGR_STALE community, depreferenced, and 
        withdrawn from routers not supporting LLGR. Like traditional BGP 
        graceful restart, it has three states: disabled, aware (receiving-only), 
        and enabled. Note that long-lived graceful restart requires 
        at least aware level of traditional BGP graceful restart. 
        Default: aware, unless graceful restart is disabled.
      '';
      default = null;
    };
    longLivedStaleTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        The long-lived stale time is announced in the BGP long-lived graceful
        restart capability and specifies how long the neighbor would keep stale
        routes depreferenced during long-lived graceful restart until either the
        session is re-stablished and synchronized or the stale time expires and
        routes are removed. 
        Default: 3600 seconds.
      '';
      default = null;
    };
    interpretCommunities = mkOption {
      type = types.nullOr types.bool;
      description = ''
        <a href="http://www.rfc-editor.org/info/rfc1997">RFC 1997</a> demands that BGP speaker should process well-known
        communities like no-export (65535, 65281) or no-advertise (65535,
        65282). For example, received route carrying a no-adverise community
        should not be advertised to any of its neighbors. If this option is
        enabled (which is by default), BIRD has such behavior automatically (it
        is evaluated when a route is exported to the BGP protocol just before
        the export filter).  Otherwise, this integrated processing of
        well-known communities is disabled. In that case, similar behavior can
        be implemented in the export filter.  
        Default: on.
      '';
      default = null;
    };
    enableAs4 = mkOption {
      type = types.nullOr types.bool;
      description = ''
        BGP protocol was designed to use 2B AS numbers and was extended later to
        allow 4B AS number. BIRD supports 4B AS extension, but by disabling this
        option it can be persuaded not to advertise it and to maintain old-style
        sessions with its neighbors. This might be useful for circumventing bugs
        in neighbor's implementation of 4B AS extension. Even when disabled
        (off), BIRD behaves internally as AS4-aware BGP router. 
        Default: on.
      '';
      default = null;
    };
    enableExtendedMessages = mkOption {
      type = types.nullOr types.bool;
      description = ''
        The BGP protocol uses maximum message length of 4096 bytes. This option
        provides an extension to allow extended messages with length up
        to 65535 bytes. Default: off.
      '';
      default = null;
    };
    capabilities = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Use capability advertisement to advertise optional capabilities. This is
        standard behavior for newer BGP implementations, but there might be some
        older BGP implementations that reject such connection attempts. When
        disabled (off), features that request it (4B AS support) are also
        disabled. Default: on, with automatic fallback to off when received
        capability-related error.
      '';
      default = null;
    };
    advertiseIpv4 = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Advertise IPv4 multiprotocol capability. This is not a correct behavior
        accordingTo="http://www.rfc-editor.org/info/rfc4760">RFC 4760</a>, but it is
        widespread and required by some BGP implementations (Cisco and Quagga).
        This option is relevant to IPv4 mode with enabled capability
        advertisement only. 
        Default: on.
      '';
      default = null;
    };
    disableAfterError = mkOption {
      type = types.nullOr types.bool;
      description = ''
        When an error is encountered (either locally or by the other side),
        disable the instance automatically and wait for an administrator to fix
        the problem manually. 
        Default: off.
      '';
      default = null;
    };
    disableAfterCease = mkOption {
      type = types.nullOr (types.either types.bool types.str);
      description = ''
        When a Cease notification is received, disable the instance automatically 
        and wait for an administrator to fix the problem manually. When used with 
        switch argument, it means handle every Cease subtype with the exception of 
        connection collision. Default: off.

        The set-of-flags allows to narrow down relevant Cease subtypes. 
        The syntax is {flag [, ...] }, where flags are: cease, prefix limit hit, 
        administrative shutdown, peer deconfigured, administrative reset, 
        connection rejected, configuration change, connection collision, out of resources.
      '';
      default = null;
    };
    holdTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        Time in seconds to wait for a Keepalive message from the other side
        before considering the connection stale. Default: depends on agreement
        with the neighboring router, we prefer 240 seconds if the other side is
        willing to accept it.
      '';
      default = null;
    };
    startupHoldTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        Value of the hold timer used before the routers have a chance to exchange
        open messages and agree on the real value. 
        Default: 240 seconds.
      '';
      default = null;
    };
    keepaliveTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        Delay in seconds between sending of two consecutive Keepalive messages.
        Default: One third of the hold time.
      '';
      default = null;
    };
    connectDelayTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        Delay in seconds between protocol startup and the first attempt to
        connect. 
        Default: 5 seconds.
      '';
      default = null;
    };
    connectRetryTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        Time in seconds to wait before retrying a failed attempt to connect.
        Default: 120 seconds.
      '';
      default = null;
    };
    errorWaitTime = mkOption {
      type = types.nullOr types.str;
      description = ''
        number,number

        Minimum and maximum delay in seconds between a protocol failure 
        (either local or reported by the peer) and automatic restart. 
        Doesn't apply when disable after error is configured. If consecutive 
        errors happen, the delay is increased exponentially until it 
        reaches the maximum. 
        Default: 60, 300.
      '';
      default = null;
    };
    errorForgetTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        Maximum time in seconds between two protocol failures to treat them as a
        error sequence which makes <code>error wait time</code> increase exponentially.
        Default: 300 seconds.
      '';
      default = null;
    };
    pathMetric = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Enable comparison of path lengths when deciding which BGP route is the
        best one. 
        Default: on.
      '';
      default = null;
    };
    medMetric = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Enable comparison of MED attributes (during best route selection) even
        between routes received from different ASes. This may be useful if all
        MED attributes contain some consistent metric, perhaps enforced in
        import filters of AS boundary routers. If this option is disabled, MED
        attributes are compared only if routes are received from the same AS
        (which is the standard behavior). 
        Default: off.
      '';
      default = null;
    };
    deterministicMed = mkOption {
      type = types.nullOr types.bool;
      description = ''
        BGP route selection algorithm is often viewed as a comparison between
        individual routes (e.g. if a new route appears and is better than the
        current best one, it is chosen as the new best one). But the proper
        routeSelection="http://www.rfc-editor.org/info/rfc4271">RFC 4271</a>, cannot be fully
        implemented in that way. The problem is mainly in handling the MED
        attribute. BIRD, by default, uses an simplification based on individual
        route comparison, which in some cases may lead to temporally dependent
        behavior (i.e. the selection is dependent on the order in which routes
        appeared). This option enables a different (and slower) algorithm
        implementingProper="http://www.rfc-editor.org/info/rfc4271">RFC 4271</a> route selection, which is
        deterministic. Alternative way how to get deterministic behavior is to
        use <code>med metric</code> option. This option is incompatible with 
        <a href="?get_doc&amp;v=20&amp;f=bird-2.html#dsc-table-sorted">sorted tables</a>.  
        Default: off.
      '';
      default = null;
    };
    igpMetric = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Enable comparison of internal distances to boundary routers during best
        route selection. 
        Default: on.
      '';
      default = null;
    };
    preferOlder = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Standard route selection algorithm breaks ties by comparing router IDs.
        This changes the behavior to prefer older routes (when both are external
        andFrom="http://www.rfc-editor.org/info/rfc5004">RFC 5004</a>. 
        Default: off.
      '';
      default = null;
    };
    defaultBgpMed = mkOption {
      type = types.nullOr types.int;
      description = ''
        Value of the Multiple Exit Discriminator to be used during route
        selection when the MED attribute is missing. 
        Default: 0.
      '';
      default = null;
    };
    defaultBgpLocalPref = mkOption {
      type = types.nullOr types.int;
      description = ''
        A default value for the Local Preference attribute. It is used when
        a new Local Preference attribute is attached to a route by the BGP
        protocol itself (for example, if a route is received through eBGP and
        therefore does not have such attribute). 
        Default: 100 (0 in pre-1.2.0 versions of BIRD).
      '';
      default = null;
    };
  };
}
