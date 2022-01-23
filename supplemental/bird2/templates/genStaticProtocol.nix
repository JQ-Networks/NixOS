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
protocol static {
    ${base}

    ${optionalSwitch checkLink "check link"}
    ${optionalStr igpTable "igp table"}

    ${extraConfig}
}
''