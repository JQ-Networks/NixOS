{ lib, ... }:
with lib;
with builtins;
v4v6: cfg:
let utils = import ./utils.nix { inherit lib; };
in with utils;
if cfg != null then ''
    ${v4v6} {
        ${optionalStr cfg.table "table"}
        ${optionalStr cfg.preference "preference"}
        ${optionalStr cfg.import "import"}
        ${optionalStr cfg.export "export"}
        ${optionalSwitch cfg.importKeepFiltered "import keep filtered"}
        ${optionalStr cfg.importLimit "import limit"}
        ${optionalStr cfg.receiveLimit "receive limit"}
        ${optionalStr cfg.exportLimit "export limit"}
        ${cfg.extraConfig}
    };
'' else
  ""
