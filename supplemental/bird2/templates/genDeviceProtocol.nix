{ lib, ... }:
with lib;
with builtins;
cfg:
let
  utils = import ./utils.nix {inherit lib;};
  genProtocolBase = import ./genProtocolBase.nix {inherit lib;};
  base = genProtocolBase cfg;
in with utils;
with cfg; ''
protocol device {
    ${base}

    ${optionalInt scanTime "scan time"}
    ${optionalStr (interfaceToString interface) "interface"}
    ${optionalStr preferred "preferred"}
}
''
