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
protocol direct {
    ${base}

    ${optionalStr (interfaceToString interface) "interface"}
    ${optionalSwitch checkLink "check link"}
}
''
