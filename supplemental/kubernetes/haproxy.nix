# Load balancer for control plane
#
# In this configuration, haproxy runs on *all nodes*
# listening on ::1, like in RKE. If the node is a
# control plane node, then the load balancer will
# prefer using the apiserver on localhost (all other
# control plane nodes will be set as "backup").
#
# We listen on 6443.
# The real apiserver listens on 6444;

{ name, nodes, pkgs, lib, config, ... }:
with builtins;
let
  utils = import ./utils.nix {
    inherit nodes config lib;
  };

  cfg = utils.cfg;
  cfgFor = utils.cfgFor;

  backupFlag = node: if cfg.controlPlane && node != name then "backup" else "";
  servers = concatStringsSep "\n" (map (n:
    "  server ${(cfgFor n).nodeName} ${(cfgFor n).discoveryName}:6444 ${backupFlag n} check"
  ) utils.controlPlane);
in {
  config = lib.mkIf cfg.enable {
    services.haproxy = {
      enable = true;

      # https://github.com/kubernetes/kubeadm/blob/master/docs/ha-considerations.md#haproxy-configuration
      config = ''
        frontend kube-apiserver
          bind [::1]:6443
          mode tcp
          option tcplog
          default_backend kube-apiserver

        backend kube-apiserver
          option httpchk GET /healthz
          http-check expect status 200
          mode tcp
          option ssl-hello-chk
          balance roundrobin
        ${servers}
      '';
    };
  };
}
