# This module means Python as a (systemd) service
{ config, lib, pkgs, name, nodes, ... }:
with builtins;
with lib;
let
  cfg = config.jq-networks.supplemental.paas;
  pathType = types.submodule {
    options = {
      path = mkOption {
        type = types.str;
        description = "permanent storage directory, must be absolute";
      };
      mode = mkOption {
        type = types.str;
        description = "folder mode";
        default = "0755";
      };
      user = mkOption {
        type = types.str;
        description = "owner user";
        default = "root";
      };
      group = mkOption {
        type = types.str;
        description = "owner group";
        default = "root";
      };
    };
  };
  paasType = types.submodule {
    options = {
      codePath = mkOption {
        type = types.path;
        description = "local file or folder to import into /nix/store";
      };
      shellScript = mkOption {
        type = types.str;
        description = "the entry point of script";
      };
      pythonVersion = mkOption {
        type = types.package;
        description = ''
          Python Package
          https://github.com/NixOS/nixpkgs/blob/nixos-21.05/pkgs/development/interpreters/python/default.nix'';
        default = pkgs.unstable.python312;
      };
      workingDir = mkOption {
        type = types.nullOr pathType;
        description = "permanent storage path";
        default = null;
      };
      symlinkCodeBase = mkEnableOption "Make a full symbolic copy of code base to working dir.";
      extraSystemdServiceConfigs = mkOption {
        type = types.attrs;
        description = ''
          Systemd options.
        ''; 
        default = {};
      };
      extraSystemdTimerConfigs = mkOption {
        type = types.nullOr types.attrs;
        description = ''
          Systemd timer options.
        ''; 
        default = null;
      };
    };
  };
in
{
  options.jq-networks.supplemental.paas = mkOption {
    type = types.attrsOf paasType;
    description = "attrs of paas options";
    default = {};
  };
  config =
    {
      systemd.services = let
        genSystemdService = key: value: (
          nameValuePair
            "paas-${key}" (mkMerge [{
            description = "Python service for ${key}";
            after = [ "network.target" ];
            wantedBy = [ "default.target" ];
            path = with pkgs; [ value.pythonVersion poetry ];
            script = ''
              # install scripts
              ${optionalString (value.workingDir != null)
              (with value.workingDir;
              ''mkdir -p -m${mode} ${path}
                chown -R ${user}:${group} ${path}
                cd ${path}'')}
              ${optionalString (value.workingDir == null)
              ''cd ${value.codePath}''}
              ${optionalString value.symlinkCodeBase
              (with value.workingDir;
              ''find ${path} -type l -delete
                ln -s ${value.codePath}/* ${path}'')}

              # run scripts
              ${value.shellScript}
            '';
            serviceConfig = {
              Environment = "PYTHONPATH=${value.codePath}";
              User = if value.workingDir != null then value.workingDir.user else "root";
              Group = if value.workingDir != null then value.workingDir.group else "root";
            };
          }
          value.extraSystemdServiceConfigs
          ])
        );
      in
        mapAttrs' genSystemdService cfg;

      systemd.timers = let
        genSystemdTimer = key: value: (
          nameValuePair
            "paas-${key}" (mkMerge [{
            description = "Timer service for ${key}";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              Unit = "paas-${key}.service";
            };
          }
          value.extraSystemdTimerConfigs
          ])
        );
      in
        mapAttrs' genSystemdTimer (filterAttrs (key: value: value.extraSystemdTimerConfigs != null) cfg);
    };
}