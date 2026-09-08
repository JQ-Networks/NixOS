{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.services.jq-networks.vscode-server;

  fhs = pkgs.buildFHSEnv {
    name = "vscode-server-fhs";
    targetPkgs = p:
      (with p; [ stdenv.cc.cc curl icu libunwind libuuid lttng-ust openssl zlib krb5 ])
      ++ cfg.extraRuntimePackages;
    # `env` execs argv[1] with the remaining args.
    runScript = "env";
    # The server daemonises and must outlive the ssh bootstrap that started it.
    dieWithParent = false;
  };
in {
  options.services.jq-networks.vscode-server = {
    enable = mkEnableOption
      "running VS Code remote servers inside an FHS environment instead of patching them";

    installPaths = mkOption {
      type = types.listOf types.str;
      default = [ "/root/.vscode-server" ];
      example = [ "/root/.vscode-server" "/home/alice/.vscode-server" ];
      description = ''
        Server install directories to watch. Must be absolute: the watcher is a
        system service, so $HOME is not available.
      '';
    };

    extraRuntimePackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression "[ pkgs.dotnet-runtime ]";
      description = "Extra packages to make available inside the FHS environment.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ fhs ];

    systemd.services.vscode-server-fhs = {
      description = "Run VS Code remote servers inside an FHS environment";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      path = with pkgs; [ coreutils findutils inotify-tools gnugrep ];
      serviceConfig = {
        # inotifywait stops watching a deleted directory without exiting.
        Restart = "always";
        RestartSec = 5;
      };
      script = ''
        roots="${concatStringsSep " " cfg.installPaths}"

        # Swap the server's own node for a shim that relaunches it inside the
        # FHS environment; every binary it spawns then inherits /lib64. The
        # shim holds no store paths, so it survives deploys and GC.
        shim_one () {
          d=$1
          [ -f "$d/node" ] || return 0
          if grep -q vscode-server-fhs "$d/node" 2>/dev/null; then
            return 0
          fi
          mv -f "$d/node" "$d/node.orig"
          cat > "$d/node" <<'EOF'
        #!/bin/sh
        exec /run/current-system/sw/bin/vscode-server-fhs "$(dirname "$0")/node.orig" "$@"
        EOF
          chmod +x "$d/node"
          echo "wrapped $d/node" >&2
        }

        fix_pass () {
          for root in $roots; do
            [ -d "$root" ] || continue
            find "$root" -mindepth 1 -maxdepth 6 -type f -name node -printf '%h\0' 2>/dev/null |
              while IFS= read -r -d "" d; do shim_one "$d"; done
          done
        }

        # Re-runs on every deploy: system units are restarted by activation.
        fix_pass

        mkdir -p $roots
        inotifywait -q -m -r -e close_write,moved_to --format '%w%f' $roots |
          while read -r p; do
            case $p in
              */node) shim_one "$(dirname "$p")" ;;
            esac
          done
      '';
    };
  };
}
