{ lib, pkgs, config, ... }:
with builtins;
with lib;
let
  cfg = config.jq-networks.supplemental.ngtun;
  cfgPath = [ "jq-networks" "supplemental" "ngtun" ];

  # deprecated
  renderNetdev = name: tunnel: {
    netdevConfig = {
      Kind = "wireguard";
      Name = name;
      MTUBytes = toString tunnel.mtuBytes;
    };
    extraConfig = ''
      [WireGuard]
      PrivateKey=${cfg.node.privateKey}
      ListenPort=${toString tunnel.listenPort}
      FirewallMark=${toString cfg.global.fwMark}

      [WireGuardPeer]
      PublicKey=${tunnel.publicKey}
      AllowedIPs=0.0.0.0/0,::/0
    '' + lib.optionalString (tunnel.endpoint != null) ''
      Endpoint=${tunnel.endpoint}
    '' + lib.optionalString tunnel.persistentKeepalive ''
      PersistentKeepalive=25
    '';
  };

  renderTunnel = name: tunnel: {
    privateKey = cfg.node.privateKey;
    listenPort = tunnel.listenPort;
    fwMark = cfg.global.fwMark;
    peers = [
      ({
        publicKey = tunnel.publicKey;
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
      } // lib.optionalAttrs (tunnel.endpoint != null) {
        endpoint = tunnel.endpoint;
      } // lib.optionalAttrs (tunnel.persistentKeepalive) {
        persistentKeepalive = 25;
      })
    ];
  };

  renderNetwork = name: tunnel:
    let
      llnum = toString tunnel.linkLocalId;
      myId = toString tunnel.myId;
      peerId = toString tunnel.peerId;
    in assert (lib.assertMsg config.networking.useNetworkd
      "systemd-networkd must be enabled for ngtun to work"); {
        inherit name;

        # address = [ "fe80:ca11:ab1e::${peerId}.${myId}.${myId}.${peerId}/64" ];
        addresses = [
          {
            addressConfig = {
              Address = "169.254.${myId}.${peerId}/32";
              Peer = "169.254.${peerId}.${myId}/32";
              Scope = "link";
            };
          }
          {
            addressConfig = {
              Address =
                "bbbb:ca11:ab1e::${peerId}.${myId}.${myId}.${peerId}/128";
              Peer = "bbbb:ca11:ab1e::${myId}.${peerId}.${peerId}.${myId}/128";
              Scope = "link";
            };
          }
        ];
        networkConfig = { LinkLocalAddressing = "no"; };
      };

  renderFirewall = name: tunnel: {
    proto = "udp";
    dport = tunnel.listenPort;
    action = "ACCEPT";
  };
in {
  config = lib.mkIf cfg.enable {
    systemd.network.netdevs = lib.mapAttrs renderNetdev cfg.generatedTunnels;
    systemd.network.networks = lib.mapAttrs renderNetwork cfg.generatedTunnels;

    # supplemental.networking.wireguard.tunnels = lib.mapAttrs renderTunnel cfg.generatedTunnels;

    jq-networks.supplemental.firewall.filterInputRules =
      lib.mapAttrsToList renderFirewall cfg.generatedTunnels;
    boot.extraModulePackages =
      optional (versionOlder config.boot.kernelPackages.kernel.version "5.6")
      config.boot.kernelPackages.wireguard;
    boot.kernelModules = [ "wireguard" ];
    environment.systemPackages = with pkgs; [ wireguard-tools ];
  };
}
