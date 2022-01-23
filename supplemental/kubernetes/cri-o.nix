{ config, pkgs, lib, ... }:
with builtins;
with lib;
let
  utils = import ./utils.nix {
    inherit nodes config lib;
  };

  cfg = utils.cfg;

  copyFile = filePath: pkgs.runCommandNoCC (builtins.unsafeDiscardStringContext (builtins.baseNameOf filePath)) {} ''
    cp ${filePath} $out
  '';
in mkIf cfg.enable {
  # The current cri-o module sets a CNI configuration
  # which totally doesn't work for us...
  virtualisation.cri-o.enable = false;

  virtualisation.containers.enable = true;

  environment.systemPackages = [
    cfg.crio.package pkgs.cri-tools
  ];

  environment.etc."crictl.yaml".source = copyFile "${pkgs.cri-o-unwrapped.src}/crictl.yaml";

  environment.etc."crio/crio.conf.d/00-default.conf".text = ''
    [crio]
    storage_driver = "${cfg.crio.storageDriver}"
    root = "${cfg.crio.root}"
    version_file_persist = "${cfg.crio.versionFilePersist}"
    storage_option = [${concatStringsSep " " (map (x: "\"${x}\"") cfg.crio.storageOption)}]

    [crio.network]
    plugin_dirs = ["/opt/cni/bin/"]

    [crio.runtime]
    cgroup_manager = "systemd"
    log_level = "info"
    pinns_path = "${utils.cfg.crio.package}/bin/pinns"
    hooks_dir = []
    default_runtime = "crun"
    [crio.runtime.runtimes]
    [crio.runtime.runtimes.crun]
  '';

  systemd.services.crio = {
    description = "Container Runtime Interface for OCI (CRI-O)";
    documentation = [ "https://github.com/cri-o/cri-o" ];
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = [ cfg.crio.package ] ++
      (if cfg.crio.storageDriver == "zfs" then [ pkgs.zfs ] else []);
    serviceConfig = {
      Type = "notify";
      ExecStart = "${cfg.crio.package}/bin/crio";
      ExecReload = "/bin/kill -s HUP $MAINPID";
      TasksMax = "infinity";
      LimitNOFILE = "1048576";
      LimitNPROC = "1048576";
      LimitCORE = "infinity";
      OOMScoreAdjust = "-999";
      TimeoutStartSec = "0";
      Restart = "on-abnormal";
    };
  };
}
