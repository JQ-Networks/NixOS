{ lib, config, pkgs, ... }:
with lib;
let
  portMappingType = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "tcp" "udp" "http" "https" "stcp" "xtcp" ];
        description = "protocol type";
      };
      localIp = mkOption {
        type = types.str;
        description = "local ip to forward";
        example = "127.0.0.1";
      };
      localPort = mkOption {
        type = types.port;
        description = "local port to forward";
      };
      remotePort = mkOption {
        type = types.port;
        description = "port to use on server";
      };
      extraConfig = mkOption {
        type = types.attrs;
        description = "other config";
        default = { };
      };
    };
  };
  genConfig = serviceName:
    let
      cfg = config.jq-networks.services.${serviceName};
      bindPort = cfg.bindPort;
      genSubConfig = mapAttrs (key: value:
        ({
          type = value.type;
          local_ip = value.localIp;
          local_port = value.localPort;
          remote_port = value.remotePort;
        } // value.extraConfig));
    in lib.generators.toINI { } ({
      common = {
        server_addr = cfg.serverAddr;
        server_port = cfg.serverPort;
        authentication_method = "token";
        token = cfg.token;
        authenticate_heartbeats = true;
        authenticate_new_work_conns = true;
      };
    } // (genSubConfig cfg.portMappings));
  genCfgFile = serviceName:
    builtins.toFile "${serviceName}-config.ini" (genConfig serviceName);
  frpcConfig = {
    enable = mkEnableOption "frpc service";
    serverAddr = mkOption {
      type = types.str;
      description = "frpc server address to connect";
    };
    serverPort = mkOption {
      type = types.port;
      example = 7123;
      description = "frpc server listen port to connect";
    };

    token = mkOption {
      type = types.str;
      description = "frpc server password";
    };

    portMappings = mkOption {
      type = types.attrsOf portMappingType;
      description = "config of port mappings";
    };
  };
in {
  # TODO refactor for code readability and multi server config
  options.jq-networks.services = (listToAttrs (map (x: {
    name = "frpc${toString x}";
    value = frpcConfig;
  }) ((range 0 9) ++ [ "" ])));

  config.environment.systemPackages = with pkgs;
    let
      enable = any (x: x)
        (map (x: config.jq-networks.services."frpc${toString x}".enable)
          ((range 0 9) ++ [ "" ]));
    in mkIf enable [ unstable.frp ];

  config.systemd.services = let
    genFrpcService = serviceName:
      let cfgFile = genCfgFile serviceName;
      in {
        description = serviceName;
        after = [ "network.target" ];
        wantedBy = [ "default.target" ];
        path = [ pkgs.unstable.frp ];
        script = ''
          frpc -c ${cfgFile}
        '';
        serviceConfig = { Restart = "always"; };
      };
  in (listToAttrs (remove { } (map (x:
    let serviceName = "frpc${toString x}";
    in if config.jq-networks.services.${serviceName}.enable then {
      name = serviceName;
      value = genFrpcService serviceName;
    } else
      { }) ((range 0 9) ++ [ "" ]))));

}
