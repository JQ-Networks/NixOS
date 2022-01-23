{ lib, ... }:
with lib;
with builtins;
let base = import ./protocolTypeBase.nix { inherit lib; };
in types.submodule {
  options = base // {
    scanTime = mkOption {
      type = types.nullOr types.int;
      description = ''
        Time in seconds between two scans of the network interface list. On
        systems where we are notified about interface status changes
        asynchronously (such as newer versions of Linux), we need to scan the
        list only in order to avoid confusion by lost notification messages,
        so the default time is set to a large value.
      '';
      default = null;
    };
    interface = mkOption {
      type = types.listOf types.str;
      description = ''
        By default, the Device protocol handles all interfaces without any
        configuration. Interface definitions allow to specify optional
        parameters for specific interfaces. See 
        <a href="?get_doc&amp;v=20&amp;f=bird-3.html#proto-iface">interface</a> common option for detailed description. Currently only
        one interface option is available:
      '';
      default = [];
    };
    preferred = mkOption {
      type = types.nullOr types.str;
      description = ''
        IP

        If a network interface has more than one IP address, BIRD chooses one of
        them as a preferred one. Preferred IP address is used as source address
        for packets or announced next hop by routing protocols. Precisely, BIRD
        chooses one preferred IPv4 address, one preferred IPv6 address and one
        preferred link-local IPv6 address. By default, BIRD chooses the first
        found IP address as the preferred one.
        Note: This option allows to specify which IP address should be preferred. May
        be used multiple times for different address classes (IPv4, IPv6, IPv6
        link-local). In all cases, an address marked by operating system as
        secondary cannot be chosen as the primary one.
      '';
      default = null;
    };
  };
}
