# This module sets up an L2TP over IPSec server
{ lib, config, pkgs, ... }:
with lib;
with builtins;
let
  cfg = config.jq-networks.services.l2tp;
in
{
  options.jq-networks.services.l2tp = {
    enable = mkEnableOption "enable L2TP";
    psk = mkOption {
      type = types.str;
      example = "test";
    };
    users = mkOption {
      type = types.attrs;
      description = "user/password pair";
      default = {};
      example = {
        "alice" = "alicepassword";
        "bob" = "bobpassword";
      };
    };
    openFirewall = mkEnableOption "open port 500/4500";
  };
  config = mkIf cfg.enable {
    virtualisation = {
      docker = {
        enable = true;
      };
      oci-containers = {
        backend = "docker";
        containers = {
          ipsec-vpn-server = {
            image = "hwdsl2/ipsec-vpn-server";
            autoStart = true;
            ports = [ "500:500/udp" "4500:4500/udp"];
            extraOptions = ["--privileged"];
            environment = {
              VPN_IPSEC_PSK = cfg.psk;
              VPN_USER = head (attrNames cfg.users);
              VPN_PASSWORD = head (attrValues cfg.users);
              VPN_ADDL_USERS = concatStringsSep " " (drop 1 (attrNames cfg.users));
              VPN_ADDL_PASSWORDS = concatStringsSep " " (drop 1 (attrValues cfg.users));
            };
          };
        };
      };
    };

    # firewall
    jq-networks.supplemental.firewall = mkIf cfg.openFirewall {
      ip.filter.chains.input = {
        rules = [
          {
            proto = "udp";
            dport = [ 500 4500 ];
            action = "ACCEPT";
          }
        ];
      };
    };
  };
}
