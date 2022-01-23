{ pkgs, ... }:
let
  keycloak = pkgs.keycloak;
  jdbc = pkgs.zhaofeng.firefly-postgresql-jdbc;
  configuration = ./configuration;
  ephemeral = "/tmp/keycloak";

  preScript = pkgs.writeScript "keycloak-start-pre.sh" ''
    #!${pkgs.runtimeShell}
    ${pkgs.coreutils}/bin/mkdir -p ${ephemeral}/configuration
    ${pkgs.coreutils}/bin/cp ${configuration}/* ${ephemeral}/configuration
  '';
in {
  systemd.services.keycloak = {
    description = "Keycloak";

    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStartPre = preScript;
      ExecStart = "${keycloak}/bin/standalone.sh -c standalone.xml -Djboss.server.config.dir=${ephemeral}/configuration -Djboss.server.data.dir=${ephemeral}/data -Djboss.server.log.dir=${ephemeral}/log -Djboss.server.temp.dir=${ephemeral}/tmp";
      Environment = "JBOSS_MODULEPATH=${keycloak}/modules:${jdbc}";

      ProtectHome = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      LockPersonality = true;
      RestrictRealtime = true;
      PrivateMounts = true;
      PrivateTmp = true;

      User = "nobody";
      Group = "nogroup";
    };
  };
}