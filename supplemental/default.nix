{ config, pkgs, lib, ... }: {
  imports = [
    ./firewall
    ./nftables
    ./ngtun
    ./kubernetes
    ./bird2
    ./paas
    ./rename-interfaces
    ./vouch
  ];
}
