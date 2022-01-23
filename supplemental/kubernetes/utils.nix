{ nodes, config, lib }:
with builtins;
rec {
  unbracket = str: lib.strings.removeSuffix "]" (lib.strings.removePrefix "[" str);

  cfg = config.jq-networks.supplemental.kubernetes;

  # List of machines in the cluster
  members = attrNames (lib.filterAttrs (n: v:
    v.config.jq-networks.supplemental.kubernetes.enable &&
    v.config.jq-networks.supplemental.kubernetes.cluster == cfg.cluster
  ) nodes);

  # List of machines that are control plane nodes
  controlPlane = filter (n:
    (cfgFor n).controlPlane
  ) members;

  cfgFor = node: nodes.${node}.config.jq-networks.supplemental.kubernetes;
}
