{ config, pkgs, lib, ... }: {
  imports = [
    ./cloudreve
    ./code-server
    ./ddclient
    ./firewall
    ./frps
    ./frpc
    ./l2tp
    ./mtg
    ./nginx
    ./ppp
    ./transmission
  ];
}
