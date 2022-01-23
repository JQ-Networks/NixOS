{ lib, ... }:
with lib;
with builtins;
cfg:
let
  utils = import ./utils.nix {inherit lib;};
  genChannel = import ./genChannel.nix {inherit lib;};
  channels = utils.configToString (mapAttrsToList genChannel cfg.channels);
in with utils; ''
  ${optionalSwitch cfg.disabled "disabled"}
  ${optionalStr cfg.debug "debug"}
  ${optionalStr cfg.mrtdump "mrtdump"}
  ${optionalStr cfg.routerId "router id"}
  ${optionalStr cfg.description "description"}
  ${optionalStr cfg.vrf "vrf"}
  ${channels}
''
