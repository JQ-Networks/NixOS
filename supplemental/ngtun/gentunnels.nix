{ lib, pkgs, name, nodes, config, ... }@context:
with builtins;
let
  cfg = config.jq-networks.supplemental.ngtun;
  cfgPath = [ "jq-networks" "supplemental" "ngtun" ];
  utils = import ./utils.nix context;

  getConfigFor = nodeName:
    lib.attrsets.getAttrFromPath cfgPath nodes.${nodeName}.config;

  # attrset of: group name -> list of nodes
  # FIXME: Performance
  groups = lib.foldl (
    collect: nodeName:
      let
        nodeConf = getConfigFor nodeName;
      in
        assert (
          lib.assertMsg (
            nodeName == name || cfg.node.id == null
            || cfg.node.id != nodeConf.node.id
          )
            "${nodeName}'s ID cannot be the same as ${name}'s"
        );
        lib.foldl (
          collect: groupName:
            collect // {
              "${groupName}" = (collect.${groupName} or []) ++ [ nodeName ];
            }
        ) collect nodeConf.node.groups
  ) {} (attrNames nodes);

  # list of manually specified peers for this node
  # may have duplicates
  manualPeers = assert (
    lib.assertMsg (!elem name cfg.node.extraPeers)
      "${name}'s extraPeers cannot contain itself"
  );
    (
      lib.foldl (
        collect: nodeName:
          collect ++ (
            if nodeName != name
            && elem name (getConfigFor nodeName).node.extraPeers then
              [ nodeName ]
            else
              []
          )
      ) cfg.node.extraPeers (attrNames nodes)
    );

  # deduplicated list of our peers!
  # Some O(n^2) shit though
  #
  # Note that for each group that we are a member of, we don't
  # necessarily peer with each one (on the contrary, the default
  # is noop)!
  myPeers = lib.lists.unique (
    lib.foldl (
      collect: groupName:
        let
          members = groups.${groupName};
          groupCfg = cfg.groups.${groupName} or cfg.defaultGroupConfig;
        in
          collect ++ (
            if elem name members then
              filter (n: n != name)
                (
                  if groupCfg.fullMesh || elem name groupCfg.hubs then
                    members
                  else
                    groupCfg.hubs
                )
            else
              []
          )
    ) manualPeers (attrNames groups)
  );

  # Address family to use with peer
  tunnelProtocolOf = peer:
    let
      peerConf = getConfigFor peer;
      mySupport = cfg.node.supportedFamilies;
      peerSupport = peerConf.node.supportedFamilies;
    in
      if (elem "ipv4" mySupport) && (elem "ipv4" peerSupport) then
        "ipv4"
      else if (elem "ipv6" mySupport) && (elem "ipv6" peerSupport) then
        "ipv6"
      else
        throw
          "There is no common protocol between ${name} and ${peer}. ${name} only supports ${
          toJSON mySupport
          }, while ${peer} only supports ${toJSON peerSupport}.";

  # Listen port for peer to connect to
  listenPort = self: peer:
    let
      selfConf = getConfigFor self;
      peerConf = getConfigFor peer;
    in
      assert (
        lib.assertMsg (selfConf.node.id != null)
          "${self}'s ID cannot be null"
      );
      assert (
        lib.assertMsg (peerConf.node.id != null)
          "${peer}'s ID cannot be null"
      );
      cfg.global.portBase + selfConf.node.id * 100 + peerConf.node.id;

  # Incorrect host-port concatenation :(
  concatHostPort = host: port:
    let
      ipv6Literal = lib.hasInfix ":" host;
    in
      if ipv6Literal then
        "[${host}]:${toString port}"
      else
        "${host}:${toString port}";

  # Endpoint of the peer to use
  # This may be null
  endpointOf = peer:
    let
      family = tunnelProtocolOf peer;
      peerConf = getConfigFor peer;
      peerPort = listenPort peer name;
      peerHost = peerConf.node.endpoint.${family};
    in
      if peerHost != null then concatHostPort peerHost peerPort else null;

  # Cost of the connection to a peer
  costFor = peer:
    let
      myCost = cfg.node.costs.${peer} or null;
      peerCost = (getConfigFor peer).node.costs.${name} or null;
    in
      if myCost == null && peerCost == null then
        null
      else if myCost != null && peerCost == null then
        myCost
      else if myCost == null && peerCost != null then
        peerCost
      else
        lib.max myCost peerCost;

  interfaceNameFor = peer:
    let
      fullName = "t-${peer}";
    in
      substring 0 15 fullName;

  publicKeyFor = peer:
    let
      peerConf = getConfigFor peer;
    in
      assert (
        lib.assertMsg (peerConf.node.privateKey != null)
          "${peer} does not have a private key specified"
      );
      utils.getPublicKey peerConf.node.privateKey;

  linkLocalIdFor = peer:
    let
      myId = cfg.node.id;
      peerId = (getConfigFor peer).node.id;
    in
      if myId < peerId then
        2
      else if myId > peerId then
        1
      else
        throw "${peer}'s ID cannot be the same as ${name}'s";

  persistentKeepaliveFor = peer:
    let
      family = tunnelProtocolOf peer;
      myEndpoint = cfg.node.endpoint.${family};
      preference = cfg.node.persistentKeepalive;
    in
      if preference == "yes" then
        true
      else if preference == "no" then
        false
      else
        myEndpoint == null;

  tunnels = let
    myId = cfg.node.id;
    recursiveMerge = attrList:
      with lib;
      let
        f = attrPath:
          zipAttrsWith (
            n: values:
              if tail values == []
              then head values
              else if all isList values
              then unique (concatLists values)
              else if all isAttrs values
              then f (attrPath ++ [ n ]) values
              else last values
          );
      in
        f [] attrList;

    overrides = recursiveMerge (
      lib.forEach cfg.endpointOverrides (
        override: {
          "${override.src}" = {
            "${override.dst}" = override;
          };
        }
      )
    );
    overrideEndpointOf = peer: override:
      let
        family = tunnelProtocolOf peer;
        peerConf = getConfigFor peer;
        peerPort = override.connectPort or (listenPort peer name);
        peerHost = override.endpoint.${family};
      in
        if peerHost != null then concatHostPort peerHost peerPort else null;
  in
    listToAttrs (
      map (
        peer: {
          name = interfaceNameFor peer;
          value = {
            inherit peer;
            endpoint = endpointOf peer;
            listenPort = listenPort name peer;
            publicKey = publicKeyFor peer;
            linkLocalId = linkLocalIdFor peer;
            persistentKeepalive = persistentKeepaliveFor peer;
            myId = myId;
            peerId = (getConfigFor peer).node.id;
            mtuBytes = lib.min cfg.node.mtuBytes (getConfigFor peer).node.mtuBytes;
          } // (if costFor peer != null then { cost = costFor peer; } else {})
          // (
            if (hasAttr name overrides) && (hasAttr peer overrides.${name}) then {
              endpoint = overrideEndpointOf peer overrides.${name}.${peer};
              listenPort = if overrides.${name}.${peer}.listenPort != null then
                overrides.${name}.${peer}.listenPort
              else (listenPort name peer);
            } else {}
          )
          ;
        }
      ) myPeers
    );

in
lib.mkIf cfg.enable {
  jq-networks.supplemental.ngtun.generatedTunnels = tunnels;
}
