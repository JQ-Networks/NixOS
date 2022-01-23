{ config, lib, pkgs, ... }:
{
  environment.etc = {
    "ppp/ip-up" = {
      mode = "0755";
      text = ''
        #!${pkgs.bash}/bin/bash

        # When the ppp link comes up, this script is called with the following
        # parameters
        #       $1      the interface name used by pppd (e.g. ppp3)
        #       $2      the tty device name
        #       $3      the tty device speed
        #       $4      the local IP address for the interface
        #       $5      the remote IP address
        #       $6      the parameter specified by the 'ipparam' option to pppd

        IFACE="$1"
        IPADDR="$4"
        GATEWAY="$5"
        DEFAULT_GATEWAY="$6"

        networkctl reconfigure $IFACE
        sleep 5
        ${pkgs.iproute}/bin/ip route add default dev $IFACE

      '';
    };
  };
}
