{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.workerd;

  # This function generates the workerd.capnp configuration file from the NixOS module options.
  generateConfig = workers:
    let
      # Helper to format bindings
      formatBinding = name: binding:
        let
          # Determine the binding type and value
          bindingContent =
            if binding.fromFile != null then "text = embed \"${binding.fromFile}\""
            else if binding.fromText != null then "text = \"${binding.fromText}\""
            else "null"; # Fallback or error, should be handled by options validation

        in
        ''
          (name = "${name}", ${bindingContent})
        '';

      # Helper to format worker definitions
      formatWorker = name: worker:
        let
          workerBindings = concatStringsSep ",\n              " (mapAttrsToList formatBinding worker.bindings);
          # Each worker itself is a service, and it can define additional services
          # For now, we assume the worker itself is the main service for its name
          # and any additional services are defined within its 'services' option.
          additionalServices = concatStringsSep ",\n              " (map (s: "(name = \"${s.name}\", worker = .${name})") worker.services);
        in
        ''
          (name = "${name}", worker = (
            serviceWorkerScript = embed "${worker.script}",
            compatibilityDate = "2023-02-28", # TODO: Make configurable
            bindings = [
              ${workerBindings}
            ]
          ))
          ${optionalString (additionalServices != "") ",\n" + additionalServices}
        '';

      # Helper to format socket definitions
      formatSocket = socket:
        let
          httpConfig = if socket.http then "http = ()" else "";
        in
        ''
          (name = "${socket.name}", address = "${socket.address}", ${httpConfig}, service = "${socket.service}")
        '';

      # Collect all services from all workers
      allServices = concatStringsSep ",\n" (mapAttrsToList formatWorker workers);

      # Collect all sockets from all workers
      allSockets = concatStringsSep ",\n" (flatten (mapAttrsToList (name: worker: map formatSocket worker.sockets) workers));
    in
    ''
      using Workerd = import "/workerd/workerd.capnp";

      const config :Workerd.Config = (
        services = [
          ${allServices}
        ],

        sockets = [
          ${allSockets}
        ]
      );
    '';

  configFile = pkgs.writeText "workerd-config.capnp" (generateConfig cfg.workers);

in
{
  options.services.workerd = {
    enable = mkEnableOption "workerd service";

    package = mkOption {
      type = types.package;
      default = pkgs.workerd;
      description = "The workerd package to use.";
    };

    workers = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          script = mkOption {
            type = types.path;
            description = "Path to the worker's main script (JS or Wasm).";
          };
          sockets = mkOption {
            type = types.listOf (types.submodule {
              options = {
                name = mkOption { type = types.str; };
                address = mkOption { type = types.str; };
                http = mkOption { type = types.bool; default = true; };
                service = mkOption { type = types.str; };
              };
            });
            default = [];
          };
          bindings = mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                fromText = mkOption { type = types.nullOr types.str; default = null; };
                fromFile = mkOption { type = types.nullOr types.path; default = null; };
              };
            });
            default = {};
          };
        };
      }));
      default = {};
      description = "Declarative configuration for workerd workers.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.workerd = {
      description = "workerd runtime";
      after = [ "network.target" "workerd.socket" ];
      wantedBy = [ "multi-user.target" ];
      # Requires the socket unit to be active
      requires = [ "workerd.socket" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/workerd serve ${configFile} --socket-fd http=3"; # Assuming one http socket for now
        User = "nobody"; # Run under an unprivileged user
        Group = "nogroup";
        NoNewPrivileges = true;
        Restart = "always";
      };
    };

    systemd.sockets.workerd = {
      description = "sockets for workerd";
      listenStreams = [ "0.0.0.0:8080" ]; # Example port, should be configurable
      socketConfig = {
        # Add socket specific options here if needed
      };
      wantedBy = [ "sockets.target" ];
    };
  };
}
