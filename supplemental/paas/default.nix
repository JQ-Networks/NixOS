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
      requirements = mkOption {
        type = types.str;
        description = ''
          content of requirements.txt
          use builtins.readFile to load from existing requirements.txt
        '';
        default = "";
      };
      pythonVersion = mkOption {
        type = types.str;
        description = ''
          Python Package
          https://github.com/NixOS/nixpkgs/blob/nixos-21.05/pkgs/development/interpreters/python/default.nix'';
        default = "python38";
      };
      workingDir = mkOption {
        type = types.nullOr pathType;
        description = "permanent storage path";
        default = null;
      };
      symlinkCodeBase = mkEnableOption "Make a full symbolic copy of code base to working dir.";
      restart = mkOption {
        type = types.str;
        description = ''
          Systemd restart option. 
          Choices are no, on-success, on-failure, on-abnormal, on-watchdog, on-abort, or always'';
        default = "on-failure";
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
  config = let
    pythonVenvs = let
      genPythonVenv = key: value: (
        nameValuePair
          "paas-${key}" (
          pkgs.mach-nix.mkPython {
            requirements = value.requirements;
            python = value.pythonVersion;
          }
        )
      );
    in
      mapAttrs' genPythonVenv cfg;
  in
    {
      systemd.services = let
        genSystemdService = key: value: (
          nameValuePair
            "paas-${key}" {
            description = "Python service for ${key}";
            after = [ "network.target" ];
            wantedBy = [ "default.target" ];
            path = [ (getAttr "paas-${key}" pythonVenvs) ];
            script = ''
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
              ${value.shellScript}
            '';
            serviceConfig = {
              Environment = "PYTHONPATH=${value.codePath}";
              Restart = value.restart;
            };
          }
        );
      in
        mapAttrs' genSystemdService cfg;
      environment.systemPackages = attrValues pythonVenvs;
    };
}
