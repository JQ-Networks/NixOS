{ lib, ... }:
with lib;
with builtins;
let base = import ./protocolTypeBase.nix { inherit lib; };
in types.submodule {
  options = base // {
    interface = mkOption {
      type = types.listOf types.str;
      description = ''
        By default, the Direct protocol will generate device routes for all the
        interfaces available. If you want to restrict it to some subset of
        interfaces or addresses (e.g. if you're using multiple routing tables
        for policy routing and some of the policy domains don't contain all
        interfaces), just use this clause. See 
        <a href="?get_doc&amp;v=20&amp;f=bird-3.html#proto-iface">interface</a>
        common option for detailed description. The Direct protocol uses
        extended interface clauses.
      '';
      default = [];
    };
    checkLink = mkOption {
      type = types.nullOr types.bool;
      description = ''
        If enabled, a hardware link state (reported by OS) is taken into
        consideration. Routes for directly connected networks are generated only
        if link up is reported and they are withdrawn when link disappears
        (e.g., an ethernet cable is unplugged). Default value is no.
      '';
      default = null;
    };
  };
}
