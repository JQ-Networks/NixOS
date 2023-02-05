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
        default = pkgs.python310;
      };
      extraSystemdServiceConfigs = mkOption {
        type = types.attrs;
        description = ''
          Systemd options.
        '';
        default = { };
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
    default = { };
  };
  config =
    let
      pythonVenvs =
        let
          genPythonVenv = key: value: (
            nameValuePair
              "paas-${key}"
              (
                (pkgs.poetry2nix.mkPoetryEnv {
                  projectDir = value.codePath;
                  python = value.pythonVersion;
                  editablePackageSources = {
                    my-app = value.codePath;
                  };
                  overrides = pkgs.poetry2nix.defaultPoetryOverrides.extend
                    (self: super:
                      let
                        overridePackages = traceSeq {
                          "magic-filter" = [ "setuptools" ];
                          "bs4" = [ "poetry" ];
                          "aiogram" = [ "setuptools" ];
                        };
                        genList = map (x: super.${x});
                        genMissing = mapAttrs (
                          key: value: (
                            super.${key}.overridePythonAttrs (
                              old: {
                                buildInputs = (old.buildInputs or [ ]) ++ (genList value);
                              }
                            )
                          )
                        );
                      in
                      genMissing overridePackages
                    );
                }).env
              )
          );
        in
        mapAttrs' genPythonVenv cfg;
    in
    {
      systemd.services =
        let
          genSystemdService = key: value: (
            nameValuePair
              "paas-${key}"
              (mkMerge [{
                description = "Python service for ${key}";
                after = [ "network.target" ];
                wantedBy = [ "default.target" ];
                path = [ (getAttr "paas-${key}" pythonVenvs) ];
                script = ''
                  ${value.shellScript}
                '';
              }
                value.extraSystemdServiceConfigs])
          );
        in
        mapAttrs' genSystemdService cfg;

      systemd.timers =
        let
          genSystemdTimer = key: value: (
            nameValuePair
              "paas-${key}"
              (mkMerge [{
                description = "Timer service for ${key}";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                  Unit = "paas-${key}.service";
                };
              }
                value.extraSystemdTimerConfigs])
          );
        in
        mapAttrs' genSystemdTimer (filterAttrs (key: value: value.extraSystemdTimerConfigs != null) cfg);
      environment.systemPackages = attrValues pythonVenvs;
    };
}
