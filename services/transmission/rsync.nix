{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.jq-networks.services.transmission.rsync;
  cfgTransmission = config.jq-networks.services.transmission;
  cfgRsync = config.services.rsyncd;
  rsyncdSecrets = builtins.toFile "rsyncd.secrets" cfg.rsyncdSecrets;
in {
  options.jq-networks.services.transmission.rsync = {
    enable = mkEnableOption "enable rsync for transmission download folder";
    rsyncdSecrets = mkOption {
      type = types.str;
      description = "rsyncd.secrets";
    };
  };
  config = mkIf cfg.enable {
    # firewall2
    jq-networks.services.firewall2.tcpOpenPorts = [cfgRsync.port];

    jq-networks.supplemental.firewall = {
      filterInputRules = [{
        proto = "tcp";
        dport = with cfgTransmission; "${toString cfgRsync.port}";
        action = "ACCEPT";
      }];
    };

    services.rsyncd = {
      enable = true;
      settings = {
        global = {
            uid = "transmission";
            gid = "transmission";
            "use chroot" = true;
        };
        downloads = {
          path = cfgTransmission.homeDir + "/Downloads";
          "auth users" = "rsync";
          "secrets file" = rsyncdSecrets;
          "strict modes" = "false";
        };
      };
    };
  };
}
