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
protocol kernel {
    ${base}

    ${optionalSwitch persist "persist"}
    ${optionalInt scanTime "scan time"}
    ${optionalSwitch learn "learn"}
    ${optionalInt kernelTable "kernel table"}
    ${optionalInt metric "metric"}
    ${optionalSwitch gracefulRestart "graceful restart"}
    ${optionalSwitchAndInt mergePaths "merge paths" mergePathsLimit "limit"}
}
''
