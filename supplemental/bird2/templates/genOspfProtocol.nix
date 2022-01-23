{ lib, ... }:
with lib;
with builtins;
protocolName: cfg:
let
  utils = import ./utils.nix { inherit lib; };
  genProtocolBase = import ./genProtocolBase.nix { inherit lib; };
  base = genProtocolBase cfg;

  optionalInt' = utils.optional (conf: key: "${key} ${toString conf}");

  genInterface = interfacePattern: cfg:
    with cfg;
    with utils;
    let
      result = ''
      interface "${interfacePattern}" ${optionalInt' interfaceInstance "instance"} {
          ${optionalInt cost "cost"}
          ${optionalBool stub "stub"}
          ${optionalInt hello "hello"}
          ${optionalInt poll "poll"}
          ${optionalInt retransmit "retransmit"}
          ${optionalInt transmitDelay "transmit delay"}
          ${optionalInt priority "priority"}
          ${optionalInt wait "wait"}
          ${optionalInt deadCount "dead count"}
          ${optionalInt dead "dead"}
          ${optionalSwitch secondary "secondary"}

          ${optionalIntOrString rxBuffer "rx buffer"}
          ${optionalInt txLength "tx length"}
          ${optionalStr interfaceType "type"}

          ${optionalSwitch linkLsaSuppression "link lsa suppression"}
          ${optionalSwitch strictNonbroadcast "strict nonbroadcast"}
          ${optionalSwitch realBroadcast "real broadcast"}
          ${optionalSwitch ptpNetmask "ptp netmask"}
          ${optionalSwitch checkLink "check link"}
          ${optionalSwitch bfd "bfd"}
          ${optionalInt ecmpWeight "ecmp weight"}
          ${optionalStr authentication "authentication"}
          ${
            optionalMultiline (if password != null then ''"'' + password
            + ''"'' else null) passwordSection "password"
          }
          ${optionalMultiline null neighbors "neighbors"}
      };
      '';
    in if cfg == null then "" else result;

  genVirtualLink = virtualLinkId: cfg:
    with cfg;
    with utils;
    let
      result = ''
        virtual link ${virtualLinkId} ${
          optionalInt' virtualLinkInstance "instance"
        } {
            ${optionalInt hello "hello"}
            ${optionalInt retransmit "retransmit"}
            ${optionalInt wait "wait"}
            ${optionalInt deadCount "dead count"}
            ${optionalInt dead "dead"}
            ${optionalStr authentication "authentication"}
            ${
            optionalMultiline (if password != null then ''"'' + password
            + ''"'' else null) passwordSection "password"
          }
        }
      '';
    in if cfg == null then "" else result;
  genStubNet = prefix: conf:
    let
      result = ''
        stubnet ${prefix}{
            ${conf}
        }
      '';
    in if cfg == null then "" else result;

  genOspfArea = areaName: cfg:
    with cfg;
    with utils; ''
      area ${areaName} {
          ${optionalBool stub "stub"}
          ${optionalBool nssa "nssa"}
          ${optionalSwitch summary "summary"}
          ${optionalSwitch defaultNssa "default nssa"}
          ${optionalInt defaultCost "default cost"}
          ${optionalInt defaultCost2 "default cost2"}
          ${optionalSwitch translator "translator"}
          ${optionalInt translatorStability "translator stability"}

          ${optionalMultiline null networks "networks"}
          ${optionalMultiline null external "external"}
          ${configToString (mapAttrsToList genStubNet stubnet)}

          ${configToString (mapAttrsToList genInterface interface)}
          ${configToString (mapAttrsToList genVirtualLink virtualLink)}
      };
    '';
in with utils;
with cfg; ''
protocol ospf ${version} ${protocolName} {
    ${base}

    ${optionalSwitch rfc1583compat "rfc1583compat"}
    ${optionalSwitch rfc5838 "rfc5838"}
    ${optionalInt instanceId "instance id"}
    ${optionalSwitch stubRouter "stub router"}
    ${optionalInt tick "tick"}
    ${optionalSwitchAndInt ecmp "ecmp" ecmpLimit "limit"}
    ${optionalSwitch mergeExternal "merge external"}
    ${optionalSwitchOrString gracefulRestart "graceful restart"}
    ${optionalInt gracefulRestartTime "graceful restart time"}
    ${configToString (mapAttrsToList genOspfArea area)}
}
''
