{ config
, pkgs
, lib
, privPkgs
, ... }:
let
  
  name = "projectzomboid";
  dataDir = "/var/lib/${name}";
  stopScript = pkgs.writeShellScript "projectzomboid-server-stop" ''
  echo quit > ${config.systemd.sockets."${name}".socketConfig.ListenFIFO}
  # Wait for the PID of the projectzomboid server to disappear before
  # returning, so systemd doesn't attempt to SIGKILL it.
  while kill -0 "$1" 2> /dev/null; do
    sleep 1s
  done
  '';
in
{
  users.users.${name} = {
    home = dataDir;
    createHome = true;
    isSystemUser = true;
    group = "${name}";
  };
  users.groups."${name}" = {};
  
  systemd.sockets."${name}" = {
    description = "Socket for controlling Project Zomboid Server";
    bindsTo = [ "${name}.service" ];
    socketConfig = {
      ListenFIFO = "/run/${name}.stdin";
      socketMode = "0660";
      socketUser = "${name}";
      socketGroup = "${name}";
      RemoveOnStop = true;
      FlushPending = true;
    };
  };

  systemd.services."${name}" = {
    wantedBy = [ "multi-user.target" ];
    requires = [ "${name}.socket" ];
    after    = [ "network.target" "${name}.socket" ];
    environment.PZ_HOME = "/var/lib/${name}/";
    serviceConfig = {
        Restart = "always";
        StateDirectory = "${name}";
        UMask = "0077";
        User = "${name}";
        ExecStart = "${privPkgs.projectzomboid-headless}/bin/projectzomboid-server";
        ExecStop = "${stopScript}";
        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        # Sandboxing
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
        RestrictRealtime = true;
        RestrictNamespaces = true;
      };
  };
  networking.firewall = {
    allowedUDPPorts = [ 16261 16262 ];
  };
}
