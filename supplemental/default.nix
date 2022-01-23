{ config, pkgs, lib, ... }: {
  imports = [
    ./firewall
    ./ngtun
    ./kubernetes
    ./bird2
    ./paas
    ./rename-interfaces
  ];
}
