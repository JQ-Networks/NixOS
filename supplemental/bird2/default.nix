# Bird2
{ config, pkgs, lib, ... }:
with lib;
with builtins;
let
  cfg = config.jq-networks.supplemental.bird2;

  bgpProtocolType = import ./protocols/bgpProtocolType.nix { inherit lib; };
  deviceProtocolType = import ./protocols/deviceProtocolType.nix { inherit lib; };
  directProtocolType = import ./protocols/directProtocolType.nix { inherit lib; };
  kernelProtocolType = import ./protocols/kernelProtocolType.nix { inherit lib; };
  ospfProtocolType = import ./protocols/ospfProtocolType.nix { inherit lib; };
  staticProtocolType = import ./protocols/staticProtocolType.nix { inherit lib; };

  globalOptionType = import ./globalOptionType.nix {inherit lib;};

  genBgpProtocol = import ./templates/genBgpProtocol.nix {inherit lib;};
  genDeviceProtocol = import ./templates/genDeviceProtocol.nix {inherit lib;};
  genDirectProtocol = import ./templates/genDirectProtocol.nix {inherit lib;};
  genKernelProtocol = import ./templates/genKernelProtocol.nix {inherit lib;};
  genOspfProtocol = import ./templates/genOspfProtocol.nix {inherit lib;};
  genStaticProtocol = import ./templates/genStaticProtocol.nix {inherit lib;};

  genGlobalOption = import ./genGlobalOption.nix {inherit lib;};

in {
  options.jq-networks.supplemental.bird2 = {
    enable = mkEnableOption "enable bird2";

    birdPackage = mkOption {
      description = ''
        The BIRD 2 package to use
      '';
      type = types.package;
      default = pkgs.bird2;
    };

    routerId = mkOption {
      type = types.str;
      default = "";
      description = ''
      bird router id, need to be uint32 or ipv4 format
      or "from" interface, mask, etc. (not recommended)
      '';
    };

    extraConfigPrepend = mkOption {
      type = types.lines;
      default = "";
      description = ''
      Can be anything. 
      E.g. functions, filters, templates, attributes, 
      defines, router id with from, time format,
      routing table, import
      '';
    };

    extraConfigAppend= mkOption {
      type = types.lines;
      default = "";
      description = ''
      Can be anything. 
      '';
    };

    globalOption = mkOption {
      type = globalOptionType;
      default = {};
      description = "all the global options";
    };

    bgpProtocols = mkOption {
      type = types.attrsOf bgpProtocolType;
      default = {};
      description = "all the bgp protocols";
    };

    deviceProtocols = mkOption {
      type = types.listOf deviceProtocolType;
      default = [];
      description = "all the device protocols";
    };

    directProtocols = mkOption {
      type = types.listOf directProtocolType;
      default = [];
      description = "all the direct protocols";
    };

    kernelProtocols = mkOption {
      type = types.listOf kernelProtocolType;
      default = [];
      description = "all the kernel protocols";
    };

    ospfProtocols = mkOption {
      type = types.attrsOf ospfProtocolType;
      default = {};
      description = "all the ospf protocols";
    };

    staticProtocols = mkOption {
      type = types.listOf staticProtocolType;
      default = [];
      description = "all the static protocols";
    };
  };

  config = let
  configToString = l: (foldl (a: b: a + "\n" + b) "" l);

  bgpConfig = configToString (mapAttrsToList genBgpProtocol cfg.bgpProtocols);
  deviceConfig = configToString (map genDeviceProtocol cfg.deviceProtocols);
  directConfig = configToString (map genDirectProtocol cfg.directProtocols);
  kernelConfig = configToString (map genKernelProtocol cfg.kernelProtocols);
  ospfConfig = configToString (mapAttrsToList genOspfProtocol cfg.ospfProtocols);
  staticConfig = configToString (map genStaticProtocol cfg.staticProtocols);

  globalConfig = genGlobalOption cfg.globalOption;
  # ${bgpConfig}
  # ${deviceConfig}
  # ${directConfig}
  # ${kernelConfig}
  # ${ospfConfig}
  # ${staticConfig}
  cfgFile = ''
  router id ${cfg.routerId};
  ${globalConfig}
  ${cfg.extraConfigPrepend}
  ${bgpConfig}
  ${deviceConfig}
  ${directConfig}
  ${kernelConfig}
  ${ospfConfig}
  ${staticConfig}


  ${cfg.extraConfigAppend}
  '';

  in mkIf cfg.enable {
    environment.systemPackages = [
      cfg.birdPackage
    ];

    environment.etc."bird.conf".source = pkgs.runCommandLocal "validated-bird2.conf" {
      rawConfig = cfgFile;
    } ''
      echo "$rawConfig" | grep -vE "^[ ]*\$" > $out
      ${cfg.birdPackage}/bin/bird -pc $out
    '';

    # remember to open proto 89 for ospf

    systemd.services.bird2 = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "BIRD routing daemon";
      serviceConfig = {
        Type = "forking";
        ExecStart = "${cfg.birdPackage}/bin/bird -c /etc/bird.conf";
        ExecReload = "${cfg.birdPackage}/bin/birdc configure";
        ExecStop = "${cfg.birdPackage}/bin/birdc down";
        Restart = "always";
      };
    };

    # reload service whenever config changes
    # very useful when adding new nodes
    systemd.services.bird2-config-reload = {
      wants = [ "bird2.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [
        config.environment.etc."bird.conf".source
      ];
      serviceConfig = {
        Type = "oneshot";
        TimeoutSec = 60;
        RemainAfterExit = true;
      };
      script = ''
        if /run/current-system/systemd/bin/systemctl -q is-active bird2.service ; then
          /run/current-system/systemd/bin/systemctl reload bird2.service
        fi
      '';
    };

  };
}
