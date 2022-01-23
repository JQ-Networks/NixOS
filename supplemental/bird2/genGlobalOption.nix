{ lib, ... }:
with lib;
cfg:
let 
  utils = import ./templates/utils.nix {inherit lib;};
in 
with utils; 
with cfg; ''
${optionalStr log "log"}
${optionalInt gracefulRestartWait "graceful restart wait"}
''