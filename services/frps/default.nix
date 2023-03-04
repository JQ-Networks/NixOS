{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.jq-networks.services.frps;
  genConfig = let
    bindPort = cfg.bindPort;
  in lib.generators.toINI { } {
    common = {
      bind_port = bindPort;
      authentication_method = "token";
      token = cfg.token;
      authenticate_heartbeats = true;
      authenticate_new_work_conns = true;
    };
  };
  cfg_file = builtins.toFile "frps-config.ini" genConfig;
in {
  options.jq-networks.services.frps = {
    enable = mkEnableOption "frps service";
    bindPort = mkOption {
      type = types.port;
      example = 7123;
      description = "frps server listen port";
    };

    token = mkOption {
      type = types.str;
      description = "frps server password";
    };

    openFirewall = mkEnableOption "open firewall port";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ unstable.frp ];
    systemd.services.frps = {
      description = "frps";
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];
      path = [ pkgs.unstable.frp ];
      script = ''
        frps -c ${cfg_file}
      '';
      serviceConfig = { Restart = "always"; };
    };

    # firewall2
    jq-networks.supplemental.nftables.config.filter.chains.input.rules = [
      {
        "tcp dport" = "20000-40000";
        action = "accept";
      }
      {
        "udp dport" = "20000-40000";
        action = "accept";
      }
    ];
    jq-networks.services.firewall2.tcpOpenPorts = [cfg.bindPort];
    jq-networks.services.firewall2.udpOpenPorts = [cfg.bindPort];

    jq-networks.supplemental = {
      firewall = {
        enable = true;
        filterInputRules = [
          {
            proto = "tcp";
            dport = "${toString cfg.bindPort}";
            action = "ACCEPT";
          }
          {
            proto = "udp";
            dport = "${toString cfg.bindPort}";
            action = "ACCEPT";
          }
        ];
      };
    };
  };
}
