{ lib, ... }:
with lib;
with builtins;
types.submodule {
  options = {
    log = mkOption {
      type = types.nullOr types.str;
      description = ''
        "filename" [limit "backup"] | syslog [name name] | stderr all|{ list of classes }

        Set logging of messages having the given class (either <code>all</code> or <code>{
        error|trace [, <em>...</em>] }</code> etc.) into selected destination - a file
        specified as a filename string (with optional log rotation information),
        syslog (with optional name argument), or the stderr output.

        Note: Classes are:
        <code>info</code>, <code>warning</code>, <code>error</code> and <code>fatal</code> for messages about local problems,
        <code>debug</code> for debugging messages,
        <code>trace</code> when you want to know what happens in the network,
        <code>remote</code> for messages about misbehavior of remote machines,
        <code>auth</code> about authentication failures,
        <code>bug</code> for internal BIRD bugs.
        </p><p>Logging directly to file supports basic log rotation -- there is an
        optional log file limit and a backup filename, when log file reaches the
        limit, the current log file is renamed to the backup filename and a new
        log file is created.
        </p><p>You may specify more than one <code>log</code> line to establish logging to
        multiple destinations. Default: log everything to the system log, or
        to the debug output if debugging is enabled by <code>-d</code>/<code>-D</code>
        command-line option.
        </p><p>
      '';
      default = null;
    };
    gracefulRestartWait = mkOption {
      type = types.nullOr types.int;
      description = ''
        During graceful restart recovery, BIRD waits for convergence of routing
        protocols. This option allows to specify a timeout for the recovery to
        prevent waiting indefinitely if some protocols cannot converge. Default:
        240 seconds.
      '';
      default = null;
    };
  };
}
