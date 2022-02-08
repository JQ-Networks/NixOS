# credit https://github.com/serokell/gemini-infra/blob/master/modules/mtg.nix
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption mkEnableOption;
  inherit (builtins) toString;
  cfg = config.jq-networks.services.mtg;
in
{
  options.jq-networks.services.mtg = with lib; {
    enable = mkEnableOption "mtg, alternative MTProto Proxy";

    package = mkOption {
      type = types.package;
      defaultText = "pkgs.mtg";
      default = pkgs.mtg;
      description = ''
        Package to use for the service.
      '';
    };

    httpPort = mkOption {
      type = types.int;
      default = 3128;
      example = 3000;
      description = ''
        HTTP port for clients to connect to.
      '';
    };

    secretFile = mkOption {
      type = types.path;
      description = ''
        A path to a secret file. Should contain the proxy's secret.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.mtg = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "mtg MTProto proxy server for Telegram.";

      script = ''
        ${cfg.package}/bin/mtg simple-run \
        0.0.0.0:${toString cfg.httpPort} \
        "$(cat ${cfg.secretFile})"
      '';

      serviceConfig = {
        User = "mtg";
      };
    };

    users.users = {
      mtg = {
        group = "mtg";
        isSystemUser = true;
        uid = 12306;
      };
    };

    users.groups = {
      mtg.gid = 12306;
    };

    jq-networks.supplemental.firewall = {
      filterInputRules = [
        {
          proto = "tcp";
          dport = cfg.httpPort;
          action = "ACCEPT";
        }
      ];
    };
  };
}