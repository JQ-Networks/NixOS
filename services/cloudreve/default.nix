{ config, lib, pkgs, options, ... }:

with lib;
let
  cfg = config.jq-networks.services.cloudreve;
  cfgFile = pkgs.writeText "conf.ini" ''
    [CORS]
    AllowOrigins = *
    AllowMethods = OPTIONS,GET,POST,PATCH
    AllowHeaders = *
    AllowCredentials = false
    [Thumbnail]
    MaxWidth = 400
    MaxHeight = 300
    FileSuffix = ._thumb
    [System]
    Mode = ${cfg.mode}
    Listen = 127.0.0.1:${toString cfg.port}
    ${optionalString (cfg.mode == "master") ''
    SessionSecret = ${cfg.sessionSecret}
    HashIDSalt = ${cfg.hashIdSalt}
    [Database]
    DBFile = ${cfg.dataDir}/cloudreve.db
    ''}
    ${optionalString (cfg.mode == "slave") ''
    [Slave]
    Secret = ${cfg.slaveSecret}
    ''}
  '';
in
{
  options = {
    jq-networks.services.cloudreve = {
      enable = mkEnableOption "Enable cloudreve";

      hostName = mkOption {
        type = types.str;
        description = ''
          Cloudreve hostname
        '';
      };

      port = mkOption {
        default = 5212;
        type = types.int;
        description = ''
          Cloudreve listen port
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/cloudreve";
        description = ''
          Directory to store Cloudreve database and other state/data files.
        '';
      };

      mode = mkOption {
        type = types.enum [ "master" "slave" ];
        default = "master";
        description = ''
          运行模式
        '';
      };

      slaveSecret = mkOption {
        type = types.str;
        description = ''
          从机端通信密钥, 当 Mode = slave 时需要
        '';
      };

      package = mkOption {
        default = pkgs.cloudreve;
        type = types.package;
      };

      proKey = mkOption {
        default = null;
        type = with types; nullOr str;
      };

      sessionSecret = mkOption {
        type = types.str;
      };

      hashIdSalt = mkOption {
        type = types.str;
      };
    };
  };


  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.cloudreve = {
      description = "Cloudreve Server Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${cfg.dataDir}/cloudreve -c ${cfg.dataDir}/conf.ini";
        Restart = "always";
      };

      preStart = ''
        if [[ ! -d ${cfg.dataDir} ]]; then
            mkdir -p ${cfg.dataDir}
        fi
        rm -f ${cfg.dataDir}/cloudreve
        cp ${cfg.package}/bin/cloudreve ${cfg.dataDir}/cloudreve
        ln -sf ${cfgFile} ${cfg.dataDir}/conf.ini
        ${optionalString (cfg.proKey != null) ''
            cat ${pkgs.writeText "key.bin" cfg.proKey} | base64 -d > ${cfg.dataDir}/key.bin
        ''}
      '';
    };

    # nginx proxy
    services.nginx = {
      virtualHosts."${cfg.hostName}" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          extraConfig = ''
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $host;
            proxy_redirect off;
            client_max_body_size 100000m;
          '';
        };
        useACMEHost = config.defaultDomain;
        forceSSL = true;
        http2 = false;
      };
    };
  };
}