{ lib, ... }:
with lib;
with builtins;
protocolName: cfg:
let
  utils = import ./utils.nix {inherit lib;};
  genProtocolBase = import ./genProtocolBase.nix {inherit lib;};
  base = genProtocolBase cfg;
in with utils; 
with cfg;''
protocol bgp ${protocolName} {
    ${base}

    ${optionalStr local "local"}
    ${optionalStr neighbor "neighbor"}
    ${optionalStr (interfaceToString interface) "interface"}
    ${optionalBool direct "direct"}
    ${optionalBoolOrInt multihop "multihop"}
    ${optionalStr sourceAddress "source address"}
    ${optionalStr dynamicName "dynamic name"}
    ${optionalInt dynamicNameDigits "dynamic name digits"}
    ${optionalSwitch strictBind "strict bind"}
    ${optionalSwitch checkLink "check link"}
    ${optionalSwitchOrString bfd "bfd"}
    ${optionalSwitch ttlSecurity "ttl security"}
    ${optionalQuotedStr password "password"}
    ${optionalSwitch setkey "set key"}
    ${optionalSwitch passive "passive"}
    ${optionalInt confederation "confederation"}
    ${optionalSwitch confederationMember "confederation member"}
    ${optionalBool rrClient "rr client"}
    ${optionalStr rrClusterId "rr cluster id"}
    ${optionalBool rsClient "rs client"}
    ${optionalSwitch allowBgpLocalPref "allow bgp_local_pref"}
    ${optionalBoolOrInt allowLocalAs "allow local as"}
    ${optionalSwitch enableRouteRefesh "enable route refresh"}
    ${optionalSwitchOrString gracefulRestart "graceful restart"}
    ${optionalInt gracefulRestartTime "graceful restart time"}
    ${optionalSwitchOrString longLivedGracefulRestart "long lived graceful restart"}
    ${optionalInt longLivedStaleTime "long lived stale time"}
    ${optionalSwitch interpretCommunities "interpret communities"}
    ${optionalSwitch enableAs4 "enable as4"}
    ${optionalSwitch enableExtendedMessages "enable extended messages"}
    ${optionalSwitch capabilities "capabilities"}
    ${optionalSwitch advertiseIpv4 "advertise ipv4"}
    ${optionalSwitch disableAfterError "disable after error"}
    ${optionalSwitchOrString disableAfterCease "disable after cease"}
    ${optionalInt holdTime "holdTime"}
    ${optionalInt startupHoldTime "startup hold time"}
    ${optionalInt keepaliveTime "keepalive time"}
    ${optionalInt connectDelayTime "connect delay time"}
    ${optionalInt connectRetryTime "connect retry time"}
    ${optionalStr errorWaitTime "error wait time"}
    ${optionalInt errorForgetTime "error forget time"}
    ${optionalSwitch pathMetric "path metric"}
    ${optionalSwitch medMetric "med metric"}
    ${optionalSwitch deterministicMed "deterministic med"}
    ${optionalSwitch igpMetric "igp metric"}
    ${optionalSwitch preferOlder "prefer older"}
    ${optionalInt defaultBgpMed "default bgp_med"}
    ${optionalInt defaultBgpLocalPref "default bgp_local_pref"}
}
''