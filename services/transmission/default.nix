{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.jq-networks.services.transmission;
  cfg_transmission = config.services.transmission.settings;
  cfg_networking = config.networking;
  peerPort = 52213;
in {
  imports = [ ./rsync.nix ];

  options.jq-networks.services.transmission = {
    enable = mkEnableOption "enable transmission";
    hostName = mkOption {
      type = types.str;
      description = "host name for transmission webui";
    };
    basicAuth = mkOption {
      type = types.attrs;
      default = { user = "password"; };
      description = "http auth username and password";
    };
    homeDir = mkOption {
      type = types.str;
      default = "/etc/transmission";
      description = "transmission config and downloads folder";
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      virtualHosts."${cfg.hostName}" = {
        locations."/" = {
          proxyPass = with cfg_transmission;
            "http://${rpc-bind-address}:${toString rpc-port}";
        };
        locations."/dav/" = {
          alias = "/etc/transmission/Downloads/";
          basicAuth = cfg.basicAuth;
          extraConfig = ''
          dav_methods     PUT DELETE MKCOL COPY MOVE;
          dav_ext_methods PROPFIND OPTIONS;
          dav_access      user:rw group:rw all:r;
          create_full_put_path  on;
          autoindex     on;
          '';
        };
        useACMEHost = config.defaultDomain;
        forceSSL = true;
        http2 = false;
        basicAuth = cfg.basicAuth;
      };
    };

    services.transmission = {
      enable = true;
      performanceNetParameters = true;
      home = cfg.homeDir;
      settings = {
        rpc-host-whitelist = cfg.hostName;
        dht-enabled = false;
        cache-size-mb = 128;
        peer-port = peerPort;
        peer-port-random-low = 49152;
        peer-port-random-high = 65535;
        message-level = 2;
      };
    };

    systemd.services.transmission.environment = {
      TRANSMISSION_WEB_HOME = let
        webUI = pkgs.fetchFromGitHub {
          owner = "ronggang";
          repo = "transmission-web-control";
          rev = "c26a076";
          sha256 = "07qjxkkhsqccwk58c9f5hyk72nhiriycbrwxwdv613b4ad6wdrdk";
        };
      in "${webUI}/src";
    };
    jq-networks.services.nginx.enable = true;

    # firewall2
    jq-networks.supplemental.nftables.config.filter.chains.input.rules = [
      {
        "udp dport" = with cfg_transmission; ["${toString peer-port-random-low}-${toString peer-port-random-high}" "${toString peerPort}"];
        action = "accept";
      }
      {
        "tcp dport" = with cfg_transmission; ["${toString peer-port-random-low}-${toString peer-port-random-high}" "${toString peerPort}"];
        action = "accept";
      }
    ];

    jq-networks.supplemental = {

      firewall = {
        enable = true;
        filterInputRules = [
          {
            proto = "udp";
            dport = with cfg_transmission;
              "${toString peer-port-random-low}:${
                toString peer-port-random-high
              }";
            action = "ACCEPT";
          }
          {
            proto = "tcp";
            dport = with cfg_transmission;
              "${toString peer-port-random-low}:${
                toString peer-port-random-high
              }";
            action = "ACCEPT";
          }
          {
            proto = "tcp";
            dport = with cfg_transmission; "${toString peerPort}";
            action = "ACCEPT";
          }
          {
            proto = "udp";
            dport = with cfg_transmission; "${toString peerPort}";
            action = "ACCEPT";
          }
        ];
      };
    };
  };

}
