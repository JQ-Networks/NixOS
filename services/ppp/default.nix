# Derived from https://github.com/jgillich/nixos/blob/master/services/ppp.nix 
# This module will create an interface named pppoe-wan by default
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.jq-networks.services.ppp;
in
{
  imports = [ ./ppp-up-down.nix ];
  options = {
    jq-networks.services.ppp = {
      enable = mkEnableOption "ppp client service";

      config = mkOption {
        type = types.attrsOf (
          types.submodule (
            {
              options = {
                username = mkOption {
                  type = types.str;
                  default = "";
                  description = ''
                    <literal>username</literal> of the ppp connection.
                  '';
                };

                password = mkOption {
                  type = types.str;
                  default = "";
                  description = ''
                    <literal>password</literal> of the ppp connection.
                  '';
                };

                interface = mkOption {
                  type = types.str;
                  description = "Interface which the ppp connection will use.";
                };

                ifName = mkOption {
                  type = types.str;
                  description = "Interface which ppp connection will rename to";
                  default = "pppoe-wan";
                };

                defaultRoute = mkEnableOption "add default route";

                pppoe = mkEnableOption "pppoe plugin";

                debug = mkEnableOption "debug mode";

                extraOptions = mkOption {
                  type = types.lines;
                  default = ''
                    +ipv6 set AUTOIPV6=1
                    lcp-echo-interval 5
                    lcp-echo-failure 60
                    usepeerdns
                    maxfail 1
                    mtu 1492
                    mru 1492
                  '';
                  description = "Extra ppp connection options";
                };
              };
            }
          )
        );

        default = {};

        example = literalExample ''
          {
            velox = {
              interface = "enp1s0";
              pppoe = true;
              username = "0000000000@oi.com.br";
              password = "fulano";
              extraOptions = \'\'
                noauth
                defaultroute
                persist
                maxfail 0
                holdoff 5
                lcp-echo-interval 15
                lcp-echo-failure 3
              \'\';
            };
          }
        '';

        description = ''
          Configuration for a ppp daemon. The daemon can be
          started, stopped, or examined using
          <literal>systemctl</literal>, under the name
          <literal>ppp@foo</literal>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services."ppp@" = {
      description = "PPP link to '%i'";
      wantedBy = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.ppp}/sbin/pppd call %I nodetach nolog";
        Restart = "always";
        RestartSec = 10;
      };
    };

    systemd.targets."default-ppp" = {
      description = "Target to start all default ppp@ services";
      wants = mapAttrsToList (name: cfg: "ppp@${name}.service") cfg.config;
      wantedBy = [ "multi-user.target" ];
    };

    environment.etc = mapAttrs' (
      name: cfg: nameValuePair "ppp/peers/${name}" {
        text = concatStringsSep "\n" [
          (optionalString cfg.pppoe "plugin rp-pppoe.so")
          "${cfg.interface}"
          "user \"${cfg.username}\""
          "password \"${cfg.password}\""
          "ifname ${cfg.ifName}"
          "${cfg.extraOptions}"
          (optionalString cfg.debug "debug")
        ];
      }
    ) cfg.config;

    networking.useNetworkd = true;
    systemd.network.networks = mapAttrs' (
      name: cfg: nameValuePair cfg.ifName {
        name = cfg.ifName;
        networkConfig = {
          DHCP = "ipv6";
          IPv6AcceptRA = true;
          KeepConfiguration = "static";
          DefaultRouteOnDevice = cfg.defaultRoute;
        };
        dhcpV6Config = {
          # PrefixDelegationHint = "::/60";
          ForceDHCPv6PDOtherInformation = true;
          WithoutRA = "information-request";
        };
      }
    ) cfg.config;

    jq-networks.supplemental.firewall.ip6.filter.chains.input.rules = [
      {
        proto = "udp";
        dport = [546 547];
        interface = mapAttrsToList (key: value: value.ifName) cfg.config;
        action = "ACCEPT";
      }
    ];
  };
}
