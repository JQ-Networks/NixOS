# This module means Python as a (systemd) service
{ config, lib, pkgs, name, nodes, ... }:
with builtins;
with lib;
let
  cfg = config.jq-networks.supplemental.paas;
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
      overridePackages = mkOption {
        type = types.attrsOf (types.listOf types.str);
        description = "add missing packages to dependencies";
        example = {
          "magic-filter" = [ "poetry" ];
          "bs4" = [ "setuptools" ];
          "aiogram" = [ "setuptools" ];
        };
        default = {};
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
                (pkgs.unstable.poetry2nix.mkPoetryApplication {
                  projectDir = value.codePath;
                  python = value.pythonVersion;
                  overrides = pkgs.poetry2nix.defaultPoetryOverrides.extend
                    (self: super:
                      let
                        overridePackages = {
                          "magic-filter" = [ "poetry" ];
                          "bs4" = [ "setuptools" ];
                          "aiogram" = [ "setuptools" ];
                        } // value.overridePackages;
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
                }).dependencyEnv
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
