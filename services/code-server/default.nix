{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.jq-networks.services.code-server;
  cfg_file = builtins.toFile "code-server-config.yaml" (builtins.toJSON ({
    bind-addr = "${cfg.bind.ip}:${toString cfg.bind.port}";
    auth = "none";
    cert = cfg.cert;
  }));
  cfg_networking = config.networking;
in {
  options.jq-networks.services.code-server = {
    enable = mkEnableOption "enable code-server";
    bind = {
      ip = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "ip to listen";
      };
      port = mkOption {
        type = types.port;
        default = 8280;
        description = "port to listen";
      };
    };
    basicAuth = mkOption {
      type = types.attrs;
      default = { user = "password"; };
      description = "http auth username and password";
    };

    cert = mkOption {
      type = types.bool;
      default = false;
      description = "set up certificates";
    };

    hostName = mkOption {
      type = types.str;
      description = "hostname for nginx";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ code-server ];
    systemd.services.code-server = {
      description = "code-server";
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];
      path = [ 
        pkgs.code-server
        pkgs.conda
        "/run/wrappers"
        "/root/.nix-profile"
        "/etc/profiles/per-user/root"
        "/nix/var/nix/profiles/default"
        "/run/current-system/sw"
      ];
      script = ''
        exec conda-shell -c "code-server --config ${cfg_file}"
      '';
      serviceConfig = { Restart = "always"; };
      environment = {
        SERVICE_URL="https://marketplace.visualstudio.com/_apis/public/gallery";
        ITEM_URL="https://marketplace.visualstudio.com/items";
        HOME="/root";
      };
    };
    services.nginx = {
      virtualHosts."${cfg.hostName}" = {
        locations."/" = {
          proxyPass = "http://${cfg.bind.ip}:${toString cfg.bind.port}";
          proxyWebsockets = true;
          extraConfig = ''
          proxy_set_header Accept-Encoding gzip;'';
        };
        useACMEHost = config.defaultDomain;
        forceSSL = true;
        http2 = true;
        basicAuth = cfg.basicAuth;
      };

    };
  };
}
