with builtins;
let
  lib = (import <nixpkgs> { }).lib;
  config = {
      filter = {
        family = "inet";
        name = null;
        sets = {
          allow_tcp = {
            name = null;
            type = "inet_service";
            typeOf = null;
            flags = "interval";
            elements = [ "22" "64738" ];
            extraConfigs = "";
            comment = null;
          };
        };
        maps = {
        };
        chains = {
          output = {
            type = "filter";
            hook = "output";
            priority = "100";
            policy = "accept";
            name = null;
            rules = [];
          };
          input = {
            type = "filter";
            hook = "input";
            priority = "filter";
            policy = "drop";
            name = null;
            rules = [
              {
                iifname = "lo";
                action = "accept";
              }
            ];
          };
          forward = {
            type = "filter";
            hook = "forward";
            priority = "filter";
            policy = "drop";
            name = null;
            rules = [
              {
                "tcp flags" = "syn";
                "tcp option" = "maxseg size";
                action = "set rt mtu";
              }
              {
                iifname = ["br0" "iot"];
                oifname = ["iot" "mgmt"];
                action = "accept";
                comment = "Allow lan access";
              }
            ];
          };

        };
      };
  };
  render = (import ./render.nix { inherit lib; }).genConf;
in
render config
