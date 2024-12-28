# Kubernetes!
# credit zhaofeng
{ name, nodes, config, pkgs, lib, ... }:
with builtins;
with lib;
let
  utils = import ./utils.nix {
    inherit nodes config lib;
  };

  cfg = utils.cfg;

  crioType = types.submodule {
    options = {
      package = mkOption {
        description = ''
          Package of the CRI-O runtime
        '';
        type = types.package;
        default = pkgs.cri-o;
      };
      storageDriver = mkOption {
        description = ''
          The storage driver to use
        '';
        type = types.str;
        default = "overlay";
        example = "zfs";
      };
      root = mkOption {
        description = ''
          CRI-O root
        '';
        type = types.str;
        default = "/var/lib/containers/storage";
      };
      versionFilePersist = mkOption {
        description = ''
          CRI-O persistent version file
        '';
        type = types.str;
        default = "/var/lib/crio/version";
      };
      storageOption = mkOption {
        description = ''
          CRI-O storage options
        '';
        type = types.listOf types.str;
        default = [];
        example = [
          "overlay.override_kernel_check=1"
        ];
      };
    };
  };
in {
  imports = [
    ./haproxy.nix
    ./cri-o.nix
    #./pki.nix
  ];
  options = {
    jq-networks.supplemental.kubernetes = {
      enable = mkOption {
        description = ''
          Run Kubernetes on this machine

          You need to bootstrap/configure the cluster manually
          with kubeadm.
        '';
        type = types.bool;
        default = false;
      };
      cluster = mkOption {
        description = ''
          Which cluster this node is on
        '';
        type = types.str;
        default = "default";
        example = "meowmeow";
      };
      controlPlane = mkOption {
        description = ''
          Use this machine as a control plane node

          Currently this affects the backend setup
          for the control plane load balancer.
        '';
        type = types.bool;
        default = false;
      };
      nodeName = mkOption {
        description = ''
          The name of the node

          Must be unique in the same cluster.
        '';
        default = name;
      };
      discoveryName = mkOption {
        description = ''
          Hostname for this node in /etc/hosts

          Used in certificate generation and intra-cluster
          communication.
        '';
        type = types.str;
        default = "${cfg.nodeName}.${cfg.cluster}.kube";
      };
      # publicIp = mkOption {
      #   description = ''
      #     Public-facing IP of the node

      #     Bracket this value if it's an IPv6 literal.
      #   '';
      #   type = types.str;
      # };
      privateIp = mkOption {
        description = ''
          Private IP of the node

          Bracket this value if it's an IPv6 literal.
        '';
        type = types.str;
        # default = cfg.publicIp;
      };
      crio = mkOption {
        description = ''
          CRI-O options
        '';
        type = crioType;
        default = {};
      };
      #samples = {
      #  kubeadmInitAppend = mkOption {
      #    description = ''
      #      Arguments to append to the sample `kubeadm init` command

      #      This is for your eyes only. The sample command will be
      #      available at /etc/kubernetes/kubeadm-init-command.sample
      #    '';
      #    type = types.str;
      #    default = "";
      #    example = ''
      #      --pod-network-cidr=fd99::/64 \
      #      --service-cidr=fd88::/64
      #    '';
      #  };
      #};
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kubectl kubernetes

      # kubeadm required commands & helpful debug tools
      conntrack-tools ebtables ethtool socat ipvsadm iptables
    ];

    boot.kernel.sysctl = {
      # commented because already defined globally
      # "net.ipv4.conf.all.forwarding" = 1;
      # "net.ipv6.conf.all.forwarding" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;
      "net.bridge.bridge-nf-call-ip6tables" = 1;
    };

    boot.kernelModules = [
      "br_netfilter"
    ];

    networking.extraHosts = concatStringsSep "\n" (lists.flatten (map (n: let
      nodeCfg = nodes.${n}.config.jq-networks.supplemental.kubernetes;
    in [
      # "${utils.unbracket nodeCfg.publicIp} public.${nodeCfg.discoveryName}"
      # "${utils.unbracket nodeCfg.privateIp} private.${nodeCfg.discoveryName}"
      "${utils.unbracket nodeCfg.privateIp} ${nodeCfg.discoveryName}"
    ]) utils.members) ++ [
      "::1 apiserver.kube"
    ]);

    # A list of hostnames assigned to this node, for
    # certificate generation
    #environment.etc."kubernetes/hostnames".text = ''
    #  public.${cfg.discoveryName}
    #  private.${cfg.discoveryName}
    #  ${cfg.discoveryName}
    #'' + (if cfg.controlPlane then "apiserver.kube" else "");

    # Sources:
    #
    # - https://github.com/kubernetes/release/blob/master/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service
    # - https://github.com/kubernetes/release/blob/master/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf
    systemd.services.kubelet = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      description = "kubelet: The Kubernetes Node Agent";

      path = with pkgs; [ gitMinimal openssh docker utillinux iproute2 ethtool thin-provisioning-tools iptables socat ];

      serviceConfig = {
        Environment = [
          "\"KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf\""
          "\"KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml --cgroup-driver=systemd\""
        ];
        EnvironmentFile = [
          "-/var/lib/kubelet/kubeadm-flags.env"
          "-/etc/default/kubelet"
        ];

        ExecStartPre = pkgs.writeScript "fix-kube-mask-drop" ''
          #!/bin/sh
          ${pkgs.iptables}/bin/ip6tables -t nat -N KUBE-MARK-DROP && ${pkgs.iptables}/bin/ip6tables -t nat -A KUBE-MARK-DROP -j MARK --set-xmark 0x8000/0x8000
          exit 0
        '';
        ExecStart = "${pkgs.kubernetes}/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS";

        # Never give up restarting
        Restart = "always";
        StartLimitInterval = 0;
        RestartSec = 10;
      };
    };
  };
}
