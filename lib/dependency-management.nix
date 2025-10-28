# Automatic Service Dependency Management for ATproto Services
# Provides dependency resolution, health checking, and startup coordination
{ lib, pkgs, ... }:

with lib;

rec {
  # Dependency types
  dependencyTypes = {
    required = "required";      # Service cannot start without this dependency
    optional = "optional";      # Service can start but may have reduced functionality
    soft = "soft";             # Service prefers this dependency but can work without it
    circular = "circular";      # Mutual dependency that requires special handling
  };

  # Health check strategies
  healthCheckStrategies = {
    http = "http";             # HTTP endpoint check
    tcp = "tcp";               # TCP port check
    command = "command";       # Custom command execution
    file = "file";             # File existence check
    systemd = "systemd";       # systemd service status check
  };

  # Create dependency specification
  mkDependency = {
    name,
    type ? "required",
    healthCheck ? {},
    timeout ? 30,
    retries ? 3,
    backoff ? "exponential",
    ...
  }@args:
    let
      validType = builtins.elem type (builtins.attrValues dependencyTypes);
    in
    if !validType then
      throw "Invalid dependency type: ${type}. Valid types: ${builtins.toString (builtins.attrValues dependencyTypes)}"
    else
    {
      inherit name type timeout retries backoff;
      
      healthCheck = healthCheck // {
        strategy = healthCheck.strategy or "http";
        endpoint = healthCheck.endpoint or "/health";
        port = healthCheck.port or null;
        command = healthCheck.command or null;
        file = healthCheck.file or null;
        expectedStatus = healthCheck.expectedStatus or 200;
        interval = healthCheck.interval or 10;
      };
      
      # Dependency-specific configuration
      config = args.config or {};
    };

  # Create dependency graph
  mkDependencyGraph = services:
    let
      # Extract dependencies from service configurations
      extractDependencies = serviceName: serviceConfig:
        let
          deps = serviceConfig.dependencies or [];
        in
        map (dep: {
          from = serviceName;
          to = if builtins.isString dep then dep else dep.name;
          dependency = if builtins.isString dep then 
            mkDependency { name = dep; } 
          else 
            mkDependency dep;
        }) deps;
      
      allEdges = lib.flatten (lib.mapAttrsToList extractDependencies services);
      
      # Detect circular dependencies
      detectCircularDeps = edges:
        let
          # Build adjacency list
          adjList = lib.foldl' (acc: edge:
            acc // {
              ${edge.from} = (acc.${edge.from} or []) ++ [ edge.to ];
            }
          ) {} edges;
          
          # Depth-first search for cycles
          dfsVisit = node: visited: recStack:
            if builtins.elem node recStack then
              throw "Circular dependency detected involving: ${builtins.toString recStack}"
            else if builtins.elem node visited then
              { inherit visited; }
            else
              let
                neighbors = adjList.${node} or [];
                newVisited = visited ++ [ node ];
                newRecStack = recStack ++ [ node ];
              in
              lib.foldl' (acc: neighbor:
                dfsVisit neighbor acc.visited newRecStack
              ) { visited = newVisited; } neighbors;
          
          allNodes = lib.unique (map (e: e.from) edges ++ map (e: e.to) edges);
        in
        lib.foldl' (acc: node:
          dfsVisit node acc.visited []
        ) { visited = []; } allNodes;
    in
    {
      edges = allEdges;
      nodes = lib.unique (map (e: e.from) allEdges ++ map (e: e.to) allEdges);
      
      # Validate graph (detect cycles)
      validate = detectCircularDeps allEdges;
      
      # Get dependencies for a specific service
      getDependencies = serviceName:
        builtins.filter (edge: edge.from == serviceName) allEdges;
      
      # Get dependents for a specific service
      getDependents = serviceName:
        builtins.filter (edge: edge.to == serviceName) allEdges;
      
      # Topological sort for startup order
      topologicalSort = 
        let
          # Kahn's algorithm for topological sorting
          kahnSort = nodes: edges:
            let
              # Calculate in-degrees
              inDegrees = lib.foldl' (acc: node:
                acc // { ${node} = 0; }
              ) {} nodes;
              
              inDegreesWithEdges = lib.foldl' (acc: edge:
                acc // { ${edge.to} = (acc.${edge.to} or 0) + 1; }
              ) inDegrees edges;
              
              # Find nodes with no incoming edges
              noIncoming = builtins.filter (node:
                (inDegreesWithEdges.${node} or 0) == 0
              ) nodes;
              
              # Recursive sorting
              sortRec = queue: remainingEdges: result:
                if queue == [] then
                  if remainingEdges == [] then
                    result
                  else
                    throw "Circular dependency detected - cannot create topological order"
                else
                  let
                    current = builtins.head queue;
                    restQueue = builtins.tail queue;
                    
                    # Remove edges from current node
                    outgoingEdges = builtins.filter (e: e.from == current) remainingEdges;
                    newRemainingEdges = builtins.filter (e: e.from != current) remainingEdges;
                    
                    # Update in-degrees and find new nodes with no incoming edges
                    affectedNodes = map (e: e.to) outgoingEdges;
                    newNoIncoming = builtins.filter (node:
                      let
                        newInDegree = (inDegreesWithEdges.${node} or 0) - 
                          (builtins.length (builtins.filter (e: e.to == node) outgoingEdges));
                      in
                      newInDegree == 0 && !builtins.elem node result && !builtins.elem node restQueue
                    ) affectedNodes;
                    
                    newQueue = restQueue ++ newNoIncoming;
                  in
                  sortRec newQueue newRemainingEdges (result ++ [ current ]);
            in
            sortRec noIncoming edges [];
        in
        kahnSort (builtins.attrNames services) allEdges;
    };

  # Health check implementations
  mkHealthCheck = dependency:
    let
      hc = dependency.healthCheck;
      strategy = hc.strategy;
    in
    if strategy == "http" then
      mkHttpHealthCheck dependency
    else if strategy == "tcp" then
      mkTcpHealthCheck dependency
    else if strategy == "command" then
      mkCommandHealthCheck dependency
    else if strategy == "file" then
      mkFileHealthCheck dependency
    else if strategy == "systemd" then
      mkSystemdHealthCheck dependency
    else
      throw "Unknown health check strategy: ${strategy}";

  # HTTP health check
  mkHttpHealthCheck = dependency:
    let
      hc = dependency.healthCheck;
      url = if hc.port != null then
        "http://localhost:${toString hc.port}${hc.endpoint}"
      else
        hc.endpoint;
    in
    {
      name = "http-health-check-${dependency.name}";
      
      script = ''
        #!/bin/bash
        set -euo pipefail
        
        echo "Checking HTTP health for ${dependency.name} at ${url}"
        
        for i in $(seq 1 ${toString dependency.retries}); do
          if curl -f -s -m ${toString dependency.timeout} "${url}" > /dev/null 2>&1; then
            echo "Health check passed for ${dependency.name}"
            exit 0
          fi
          
          if [ $i -lt ${toString dependency.retries} ]; then
            echo "Health check failed for ${dependency.name}, retrying in $((i * 2)) seconds..."
            sleep $((i * 2))
          fi
        done
        
        echo "Health check failed for ${dependency.name} after ${toString dependency.retries} attempts"
        exit 1
      '';
      
      timeout = dependency.timeout + (dependency.retries * 2);
    };

  # TCP health check
  mkTcpHealthCheck = dependency:
    let
      hc = dependency.healthCheck;
      port = hc.port;
    in
    {
      name = "tcp-health-check-${dependency.name}";
      
      script = ''
        #!/bin/bash
        set -euo pipefail
        
        echo "Checking TCP connectivity for ${dependency.name} on port ${toString port}"
        
        for i in $(seq 1 ${toString dependency.retries}); do
          if timeout ${toString dependency.timeout} bash -c "</dev/tcp/localhost/${toString port}"; then
            echo "TCP health check passed for ${dependency.name}"
            exit 0
          fi
          
          if [ $i -lt ${toString dependency.retries} ]; then
            echo "TCP health check failed for ${dependency.name}, retrying in $((i * 2)) seconds..."
            sleep $((i * 2))
          fi
        done
        
        echo "TCP health check failed for ${dependency.name} after ${toString dependency.retries} attempts"
        exit 1
      '';
      
      timeout = dependency.timeout + (dependency.retries * 2);
    };

  # Command health check
  mkCommandHealthCheck = dependency:
    let
      hc = dependency.healthCheck;
      command = hc.command;
    in
    {
      name = "command-health-check-${dependency.name}";
      
      script = ''
        #!/bin/bash
        set -euo pipefail
        
        echo "Running command health check for ${dependency.name}"
        
        for i in $(seq 1 ${toString dependency.retries}); do
          if timeout ${toString dependency.timeout} ${command}; then
            echo "Command health check passed for ${dependency.name}"
            exit 0
          fi
          
          if [ $i -lt ${toString dependency.retries} ]; then
            echo "Command health check failed for ${dependency.name}, retrying in $((i * 2)) seconds..."
            sleep $((i * 2))
          fi
        done
        
        echo "Command health check failed for ${dependency.name} after ${toString dependency.retries} attempts"
        exit 1
      '';
      
      timeout = dependency.timeout + (dependency.retries * 2);
    };

  # File health check
  mkFileHealthCheck = dependency:
    let
      hc = dependency.healthCheck;
      file = hc.file;
    in
    {
      name = "file-health-check-${dependency.name}";
      
      script = ''
        #!/bin/bash
        set -euo pipefail
        
        echo "Checking file existence for ${dependency.name}: ${file}"
        
        for i in $(seq 1 ${toString dependency.retries}); do
          if [ -f "${file}" ]; then
            echo "File health check passed for ${dependency.name}"
            exit 0
          fi
          
          if [ $i -lt ${toString dependency.retries} ]; then
            echo "File health check failed for ${dependency.name}, retrying in $((i * 2)) seconds..."
            sleep $((i * 2))
          fi
        done
        
        echo "File health check failed for ${dependency.name} after ${toString dependency.retries} attempts"
        exit 1
      '';
      
      timeout = dependency.timeout + (dependency.retries * 2);
    };

  # systemd health check
  mkSystemdHealthCheck = dependency:
    {
      name = "systemd-health-check-${dependency.name}";
      
      script = ''
        #!/bin/bash
        set -euo pipefail
        
        echo "Checking systemd service status for ${dependency.name}"
        
        for i in $(seq 1 ${toString dependency.retries}); do
          if systemctl is-active --quiet "${dependency.name}.service"; then
            echo "systemd health check passed for ${dependency.name}"
            exit 0
          fi
          
          if [ $i -lt ${toString dependency.retries} ]; then
            echo "systemd health check failed for ${dependency.name}, retrying in $((i * 2)) seconds..."
            sleep $((i * 2))
          fi
        done
        
        echo "systemd health check failed for ${dependency.name} after ${toString dependency.retries} attempts"
        exit 1
      '';
      
      timeout = dependency.timeout + (dependency.retries * 2);
    };

  # Generate dependency management configuration
  mkDependencyManagement = { services, startupStrategy ? "sequential", ... }@args:
    let
      dependencyGraph = mkDependencyGraph services;
      startupOrder = dependencyGraph.topologicalSort;
      
      # Generate health check scripts for all dependencies
      generateHealthChecks = serviceName: serviceConfig:
        let
          dependencies = dependencyGraph.getDependencies serviceName;
        in
        lib.listToAttrs (map (dep: {
          name = "atproto-health-check-${dep.dependency.name}";
          value = pkgs.writeScript "health-check-${dep.dependency.name}" 
            (mkHealthCheck dep.dependency).script;
        }) dependencies);
      
      # Generate dependency wait scripts
      generateDependencyWait = serviceName: serviceConfig:
        let
          dependencies = dependencyGraph.getDependencies serviceName;
          requiredDeps = builtins.filter (dep: dep.dependency.type == "required") dependencies;
          optionalDeps = builtins.filter (dep: dep.dependency.type == "optional") dependencies;
          
          waitScript = ''
            #!/bin/bash
            set -euo pipefail
            
            echo "Starting dependency coordination for ${serviceName}"
            
            # Wait for required dependencies
            ${lib.concatStringsSep "\n" (map (dep: ''
              echo "Waiting for required dependency: ${dep.dependency.name}"
              if ! ${(mkHealthCheck dep.dependency).script}; then
                echo "Required dependency ${dep.dependency.name} failed health check"
                exit 1
              fi
            '') requiredDeps)}
            
            # Check optional dependencies (don't fail if they're not available)
            ${lib.concatStringsSep "\n" (map (dep: ''
              echo "Checking optional dependency: ${dep.dependency.name}"
              if ${(mkHealthCheck dep.dependency).script}; then
                echo "Optional dependency ${dep.dependency.name} is available"
              else
                echo "Optional dependency ${dep.dependency.name} is not available, continuing anyway"
              fi
            '') optionalDeps)}
            
            echo "All dependency checks completed for ${serviceName}"
          '';
        in
        pkgs.writeScript "wait-dependencies-${serviceName}" waitScript;
    in
    {
      inherit dependencyGraph startupOrder;
      
      # systemd configuration for dependency management
      systemdConfig = lib.mkMerge (lib.mapAttrsToList (serviceName: serviceConfig:
        let
          dependencies = dependencyGraph.getDependencies serviceName;
          dependencyWaitScript = generateDependencyWait serviceName serviceConfig;
        in
        {
          # Dependency coordination service
          systemd.services."atproto-${serviceName}-deps" = {
            description = "Dependency coordination for ${serviceName}";
            wantedBy = [ "atproto-${serviceName}.service" ];
            before = [ "atproto-${serviceName}.service" ];
            
            serviceConfig = {
              Type = "oneshot";
              ExecStart = dependencyWaitScript;
              TimeoutStartSec = toString (
                lib.foldl' (acc: dep: acc + dep.dependency.timeout + (dep.dependency.retries * 2)) 
                60 dependencies
              );
              RemainAfterExit = true;
            };
          };
          
          # Update main service to depend on coordination
          systemd.services."atproto-${serviceName}" = {
            after = [ "atproto-${serviceName}-deps.service" ];
            wants = [ "atproto-${serviceName}-deps.service" ];
          };
        }
      ) services);
      
      # Health check monitoring services
      healthCheckServices = lib.mkMerge (lib.mapAttrsToList (serviceName: serviceConfig:
        let
          dependencies = dependencyGraph.getDependencies serviceName;
        in
        lib.mkMerge (map (dep: {
          # Periodic health check service
          systemd.services."atproto-monitor-${dep.dependency.name}" = {
            description = "Health monitoring for ${dep.dependency.name}";
            
            serviceConfig = {
              Type = "oneshot";
              ExecStart = (mkHealthCheck dep.dependency).script;
            };
          };
          
          # Health check timer
          systemd.timers."atproto-monitor-${dep.dependency.name}" = {
            description = "Health monitoring timer for ${dep.dependency.name}";
            wantedBy = [ "timers.target" ];
            
            timerConfig = {
              OnBootSec = "${toString dep.dependency.healthCheck.interval}s";
              OnUnitActiveSec = "${toString dep.dependency.healthCheck.interval}s";
              Persistent = true;
            };
          };
        }) dependencies)
      ) services);
    };

  # Dependency resolution utilities
  
  # Resolve service endpoints from discovery
  resolveServiceEndpoints = discoveredServices: dependencies:
    lib.mapAttrs (depName: depConfig:
      let
        discoveredService = discoveredServices.${depName} or null;
      in
      if discoveredService != null then
        depConfig // {
          healthCheck = depConfig.healthCheck // {
            port = discoveredService.port;
            endpoint = depConfig.healthCheck.endpoint;
          };
        }
      else
        depConfig
    ) dependencies;

  # Generate dependency documentation
  generateDependencyDocs = dependencyGraph:
    let
      generateServiceDocs = serviceName:
        let
          deps = dependencyGraph.getDependencies serviceName;
          dependents = dependencyGraph.getDependents serviceName;
        in
        ''
          ## ${serviceName}
          
          ### Dependencies
          ${if deps == [] then "None" else
            lib.concatStringsSep "\n" (map (dep: 
              "- **${dep.dependency.name}** (${dep.dependency.type}): ${dep.dependency.healthCheck.strategy} health check"
            ) deps)
          }
          
          ### Dependents
          ${if dependents == [] then "None" else
            lib.concatStringsSep "\n" (map (dep: 
              "- **${dep.from}**"
            ) dependents)
          }
        '';
    in
    ''
      # Service Dependency Graph
      
      ## Startup Order
      ${lib.concatStringsSep " → " dependencyGraph.topologicalSort}
      
      ## Service Details
      ${lib.concatStringsSep "\n\n" (map generateServiceDocs dependencyGraph.nodes)}
    '';
}