{ config, pkgs, lib, ... }: {
  imports = [
    ./cloudreve
    ./code-server
    ./ddclient
    ./firewall
    ./frps
    ./frpc
    ./l2tp
    ./nginx
    ./ppp
    ./transmission
  ];
}
