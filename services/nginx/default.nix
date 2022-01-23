{ name, lib, config, pkgs, ... }:
with lib;
with builtins;
let
  cfg = config.jq-networks.services.nginx;
  cfgNginx = config.services.nginx;

in
{
  options.jq-networks.services.nginx = {
    enable = mkEnableOption "nginx service";
    httpsPort = mkOption {
      type = types.int;
      default = 443;
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      commonHttpConfig = ''
        log_format detailed '$remote_addr - $remote_user [$time_local] '
        '"$request" $status $body_bytes_sent "$http_referer" '
        '"$http_user_agent" $request_length $request_time '
        '$upstream_response_length $upstream_response_time '
        '$upstream_status';
      '';

    };
  };
}
