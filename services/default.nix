{ config, pkgs, lib, ... }: {
  imports = [
    ./cloudreve
    ./code-server
    ./ddclient
    ./firewall
    ./firewall2
    ./frps
    ./frpc
    ./l2tp
    ./mtg
    ./nginx
    ./ppp
    ./transmission
  ];
}
